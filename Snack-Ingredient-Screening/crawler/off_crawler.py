#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Open Food Facts 零食标签采集器

用途：
    按品类从 Open Food Facts 公开 API 分页抓取中国零食数据，
    把每一页原始 JSON 原样保存，并把去重后的产品逐行写入 products.jsonl。

特点：
    - 限速：默认每次请求间隔 >= 4 秒（见 config.json 的 delay_seconds）
    - 重试：遇到 429 / 5xx 或网络错误时指数退避重试
    - 断点续跑：state.json 记录每个品类的下一页；已下载的页面直接复用
    - 去重：以条码 code 为主键；无条码时用原始 JSON 的 SHA-256
    - 仅使用 Python 标准库，无需 pip install

用法：
    python crawler/off_crawler.py --help
    python crawler/off_crawler.py --categories en:snacks --page-size 5 --max-pages 2 --delay 2
    python crawler/off_crawler.py
"""

import argparse
import gzip
import hashlib
import json
import logging
import random
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

BASE_URL = "https://world.openfoodfacts.org/api/v2/search"
SCRIPT_DIR = Path(__file__).resolve().parent

# 只请求需要的字段，减少响应体积
FIELDS = [
    "code",
    "product_name",
    "product_name_zh",
    "generic_name",
    "brands",
    "categories_tags",
    "ingredients_text",
    "ingredients_text_zh",
    "allergens_tags",
    "additives_tags",
    "nutriments",
    "quantity",
    "serving_size",
    "url",
    "last_modified_t",
    "countries_tags",
]

# 这些 HTTP 状态码可以重试，其他状态码直接失败
RETRY_STATUS = {408, 425, 429, 500, 502, 503, 504}

DEFAULT_CONFIG = {
    "country": "en:china",
    "categories": [
        "en:snacks",
        "en:biscuits",
        "en:chocolates",
        "en:candies",
        "en:nuts",
        "en:crisps",
        "en:cookies",
    ],
    "page_size": 100,
    "max_pages_per_category": 0,
    "delay_seconds": 4.0,
    "timeout_seconds": 30,
    "max_retries": 5,
    "backoff_base_seconds": 10.0,
    "user_agent": "SnackDB-CourseProject/1.0 (student course project; contact: your-email@example.com)",
    "output_dir": "output",
}


def now_str():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def product_key(product):
    """条码优先；没有条码时用整条 JSON 的 SHA-256 作为去重键。"""
    code = (product.get("code") or "").strip()
    if code:
        return code
    payload = json.dumps(product, sort_keys=True, ensure_ascii=False)
    return "hash:" + hashlib.sha256(payload.encode("utf-8")).hexdigest()


def slugify(value):
    return re.sub(r"[^0-9A-Za-z]+", "_", value).strip("_") or "category"


def load_config(path):
    cfg = dict(DEFAULT_CONFIG)
    if path.exists():
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        for key, value in data.items():
            if value is not None:
                cfg[key] = value
    if not cfg.get("categories"):
        raise ValueError("config.json 中的 categories 不能为空")
    # Open Food Facts 单页最多 100 条
    cfg["page_size"] = max(1, min(int(cfg["page_size"]), 100))
    return cfg


def resolve_path(value):
    path = Path(value)
    if path.is_absolute():
        return path
    return SCRIPT_DIR / path


def setup_logger(out_dir, level):
    logger = logging.getLogger("off_crawler")
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))
    logger.handlers = []
    fmt = logging.Formatter("%(asctime)s %(levelname)s %(message)s", "%Y-%m-%d %H:%M:%S")

    file_handler = logging.FileHandler(str(out_dir / "crawl.log"), encoding="utf-8")
    file_handler.setFormatter(fmt)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(fmt)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    return logger


def read_json(path):
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def write_json(path, data):
    """先写临时文件再替换，避免中途退出留下半个 JSON。"""
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
    tmp.replace(path)


def load_seen(path):
    seen = set()
    if not path.exists():
        return seen
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                item = json.loads(line)
            except ValueError:
                continue
            seen.add(product_key(item))
    return seen


def build_url(cfg, category, page):
    query = [
        ("categories_tags", category),
        ("countries_tags", cfg["country"]),
        ("page_size", cfg["page_size"]),
        ("page", page),
        ("fields", ",".join(FIELDS)),
    ]
    return BASE_URL + "?" + urllib.parse.urlencode(query, safe=":,")


def wait_for_delay(last_request_at, delay):
    if last_request_at is None:
        return
    remaining = delay - (time.time() - last_request_at)
    if remaining > 0:
        time.sleep(remaining)


def http_get_json(url, cfg, logger):
    """请求一页 JSON；失败时按指数退避重试，返回 (data, 尝试次数)。"""
    headers = {
        "User-Agent": cfg["user_agent"],
        "Accept": "application/json",
    }
    attempts = 0

    while True:
        attempts += 1
        started = time.time()
        retry_after = None

        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=cfg["timeout_seconds"]) as response:
                body = response.read()
                encoding = (response.headers.get("Content-Encoding") or "").lower()
                if "gzip" in encoding:
                    body = gzip.decompress(body)
                data = json.loads(body.decode("utf-8"))
                logger.info("    请求成功：HTTP %s，用时 %.1f 秒", response.status, time.time() - started)
                return data, attempts
        except urllib.error.HTTPError as exc:
            message = "HTTP %s" % exc.code
            if exc.headers:
                retry_after = exc.headers.get("Retry-After")
            if exc.code not in RETRY_STATUS:
                raise RuntimeError("请求失败（不可重试）：%s" % message)
        except (OSError, ValueError) as exc:
            message = "%s: %s" % (type(exc).__name__, exc)

        if attempts >= cfg["max_retries"]:
            raise RuntimeError("请求失败，已重试 %d 次：%s" % (attempts, message))

        wait = min(180.0, cfg["backoff_base_seconds"] * (2.0 ** (attempts - 1))) + random.uniform(0, 1)
        if retry_after:
            try:
                wait = max(wait, float(retry_after))
            except (TypeError, ValueError):
                pass
        logger.warning("    %s，%.1f 秒后重试（第 %d/%d 次）", message, wait, attempts, cfg["max_retries"])
        time.sleep(wait)


def crawl_category(category, cfg, paths, state, summary, seen, logger, last_request_at):
    category_state = state["categories"].setdefault(
        category, {"next_page": 1, "done": False, "pages_done": 0}
    )
    category_summary = summary["categories"].setdefault(category, {
        "pages_processed": 0,
        "requests": 0,
        "failed_requests": 0,
        "products_received": 0,
        "new_products": 0,
        "duplicates": 0,
        "done": False,
        "next_page": category_state.get("next_page", 1),
    })

    if category_state.get("done"):
        logger.info("品类 %s 已完成，跳过", category)
        category_summary["done"] = True
        return last_request_at

    page = int(category_state.get("next_page", 1))
    pages_this_run = 0
    max_pages = int(cfg.get("max_pages_per_category") or 0)
    slug = slugify(category)

    while True:
        if max_pages and pages_this_run >= max_pages:
            logger.info(
                "品类 %s 达到本次最大页数 %d，保留断点（下次从第 %d 页继续）",
                category, max_pages, page,
            )
            break

        page_file = paths["pages"] / ("%s_page_%04d.json" % (slug, page))
        attempts = 0
        data = None

        if page_file.exists():
            try:
                data = read_json(page_file)
                logger.info("[%s] 第 %d 页已存在，直接复用", category, page)
            except ValueError:
                logger.warning("[%s] 页面缓存损坏，重新下载：%s", category, page_file.name)
                page_file.unlink()

        if data is None:
            url = build_url(cfg, category, page)
            wait_for_delay(last_request_at, cfg["delay_seconds"])
            logger.info("[%s] 请求第 %d 页：%s", category, page, url)
            data, attempts = http_get_json(url, cfg, logger)
            last_request_at = time.time()
            write_json(page_file, data)

        products = data.get("products") or []
        total_count = data.get("count")

        new_products = 0
        duplicates = 0
        with paths["products"].open("a", encoding="utf-8") as fh:
            for product in products:
                key = product_key(product)
                if key in seen:
                    duplicates += 1
                    continue
                seen.add(key)
                fh.write(json.dumps(product, ensure_ascii=False) + "\n")
                new_products += 1

        category_summary["pages_processed"] += 1
        category_summary["requests"] += attempts
        category_summary["failed_requests"] += max(0, attempts - 1)
        category_summary["products_received"] += len(products)
        category_summary["new_products"] += new_products
        category_summary["duplicates"] += duplicates
        category_summary["next_page"] = page + 1

        category_state["next_page"] = page + 1
        category_state["pages_done"] = int(category_state.get("pages_done", 0)) + 1

        pages_this_run += 1

        done = False
        reason = ""
        if not products:
            done = True
            reason = "本页无数据"
        elif total_count is not None and page * cfg["page_size"] >= int(total_count):
            done = True
            reason = "已到总数 %s" % total_count
        elif len(products) < cfg["page_size"]:
            done = True
            reason = "本页不足一页"

        category_state["done"] = done
        category_summary["done"] = done

        state["updated_at"] = now_str()
        summary["updated_at"] = now_str()
        summary["total_products_saved"] = len(seen)
        write_json(paths["state"], state)
        write_json(paths["summary"], summary)

        logger.info(
            "[%s] 第 %d 页完成：收到 %d 条，新增 %d 条，重复 %d 条，累计唯一产品 %d 条",
            category, page, len(products), new_products, duplicates, len(seen),
        )

        if done:
            logger.info("品类 %s 采集完成（%s）", category, reason)
            break

        page += 1

    return last_request_at


def apply_overrides(cfg, args):
    if args.categories:
        cfg["categories"] = [item.strip() for item in args.categories.split(",") if item.strip()]
    if args.country:
        cfg["country"] = args.country
    if args.page_size is not None:
        cfg["page_size"] = max(1, min(args.page_size, 100))
    if args.max_pages is not None:
        cfg["max_pages_per_category"] = max(0, args.max_pages)
    if args.delay is not None:
        cfg["delay_seconds"] = max(0.0, args.delay)
    if args.backoff is not None:
        cfg["backoff_base_seconds"] = max(0.0, args.backoff)
    if args.timeout is not None:
        cfg["timeout_seconds"] = max(1, args.timeout)
    if args.max_retries is not None:
        cfg["max_retries"] = max(1, args.max_retries)
    if args.output_dir:
        cfg["output_dir"] = args.output_dir
    return cfg


def parse_args():
    parser = argparse.ArgumentParser(
        description="从 Open Food Facts 分页采集中国零食标签数据（只保存原始 JSON，不写数据库）"
    )
    parser.add_argument("--config", help="配置文件路径，默认 crawler/config.json")
    parser.add_argument("--categories", help="逗号分隔的品类，例如 en:snacks,en:biscuits")
    parser.add_argument("--country", help="国家标签，默认 en:china")
    parser.add_argument("--page-size", type=int, help="每页条数，最大 100")
    parser.add_argument("--max-pages", type=int, help="每个品类本次最多抓几页，0 表示不限")
    parser.add_argument("--delay", type=float, help="两次请求的最小间隔（秒），建议 >= 4")
    parser.add_argument("--backoff", type=float, help="重试退避的基准秒数，默认 10")
    parser.add_argument("--timeout", type=int, help="单次请求超时（秒）")
    parser.add_argument("--max-retries", type=int, help="失败最大重试次数")
    parser.add_argument("--output-dir", help="输出目录，默认 crawler/output")
    parser.add_argument("--reset", action="store_true", help="清空断点与产品汇总后重新开始（保留页面缓存）")
    parser.add_argument("--log-level", default="INFO", help="日志级别：DEBUG/INFO/WARNING/ERROR")
    return parser.parse_args()


def main():
    args = parse_args()
    config_path = Path(args.config).resolve() if args.config else (SCRIPT_DIR / "config.json")
    cfg = apply_overrides(load_config(config_path), args)

    out_dir = resolve_path(cfg["output_dir"])
    pages_dir = out_dir / "raw" / "pages"
    pages_dir.mkdir(parents=True, exist_ok=True)
    logger = setup_logger(out_dir, args.log_level)

    state_path = out_dir / "state.json"
    summary_path = out_dir / "crawl_summary.json"
    products_path = out_dir / "products.jsonl"
    paths = {
        "out": out_dir,
        "pages": pages_dir,
        "products": products_path,
        "state": state_path,
        "summary": summary_path,
    }

    logger.info("=" * 64)
    logger.info("Open Food Facts 零食标签采集器")
    logger.info("配置文件：%s", config_path)
    logger.info("输出目录：%s", out_dir)
    logger.info("国家/地区标签：%s", cfg["country"])
    logger.info("品类：%s", ", ".join(cfg["categories"]))
    logger.info(
        "分页大小：%d；请求间隔：%.1f 秒；最大重试：%d 次；退避基准：%.1f 秒",
        cfg["page_size"], cfg["delay_seconds"], cfg["max_retries"], cfg["backoff_base_seconds"],
    )
    logger.info("User-Agent：%s", cfg["user_agent"])
    if "your-email@example.com" in cfg["user_agent"]:
        logger.warning("请先把 config.json 里的 User-Agent 联系方式改成你自己的邮箱")
    logger.info("=" * 64)

    if args.reset:
        for path in (state_path, summary_path, products_path):
            if path.exists():
                path.unlink()
        logger.info("已重置断点与产品汇总（保留 raw/pages 页面缓存）")

    state = read_json(state_path) if state_path.exists() and not args.reset else {}
    if state.get("country") != cfg["country"] or state.get("page_size") != cfg["page_size"]:
        if state:
            logger.warning("国家或分页大小与上次不同，断点状态已重置")
        state = {"country": cfg["country"], "page_size": cfg["page_size"], "categories": {}}
    state.setdefault("categories", {})

    seen = load_seen(products_path)
    summary = {
        "started_at": now_str(),
        "finished_at": None,
        "updated_at": now_str(),
        "country": cfg["country"],
        "page_size": cfg["page_size"],
        "delay_seconds": cfg["delay_seconds"],
        "categories_requested": list(cfg["categories"]),
        "categories": {},
        "total_products_saved": len(seen),
        "output_dir": str(out_dir),
    }

    had_error = False
    last_request_at = None

    try:
        for category in cfg["categories"]:
            try:
                last_request_at = crawl_category(
                    category, cfg, paths, state, summary, seen, logger, last_request_at
                )
            except KeyboardInterrupt:
                raise
            except Exception as exc:
                had_error = True
                logger.error("品类 %s 采集失败：%s", category, exc)
                summary["categories"].setdefault(category, {})["error"] = str(exc)
    except KeyboardInterrupt:
        logger.warning("收到中断信号，正在保存断点...")
        return 130
    finally:
        summary["finished_at"] = now_str()
        summary["updated_at"] = now_str()
        summary["total_products_saved"] = len(seen)
        write_json(state_path, state)
        write_json(summary_path, summary)
        logger.info("-" * 64)
        logger.info("采集结束：唯一产品共 %d 条", len(seen))
        logger.info("原始页面：%s", pages_dir)
        logger.info("产品汇总：%s", products_path)
        logger.info("断点状态：%s", state_path)
        logger.info("运行汇总：%s", summary_path)

    return 1 if had_error else 0


if __name__ == "__main__":
    sys.exit(main())
