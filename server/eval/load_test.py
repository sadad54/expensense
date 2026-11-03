"""Concurrent load test for POST /v1/receipts/parse (parsing + categorisation, no OCR call).

    AUTH_MODE=disabled uvicorn app.main:app --port 8765
    python eval/load_test.py http://localhost:8765 --sroie /tmp/sroie/data --requests 2000 --concurrency 32

OCR latency is the external provider's and is not included.
"""
import argparse
import asyncio
import statistics
import sys
import time
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sroie_eval import rebuild_text  # noqa: E402


async def run(base: str, texts: list[str], total: int, concurrency: int) -> dict:
    latencies: list[float] = []
    errors = 0
    queue: asyncio.Queue[int] = asyncio.Queue()
    for i in range(total):
        queue.put_nowait(i)

    async def worker(client: httpx.AsyncClient) -> None:
        nonlocal errors
        while not queue.empty():
            i = queue.get_nowait()
            start = time.perf_counter()
            resp = await client.post("/v1/receipts/parse", json={"text": texts[i % len(texts)]})
            latencies.append(1000 * (time.perf_counter() - start))
            errors += resp.status_code != 200

    async with httpx.AsyncClient(base_url=base, timeout=30) as client:
        await client.get("/healthz")
        start = time.perf_counter()
        await asyncio.gather(*(worker(client) for _ in range(concurrency)))
        wall = time.perf_counter() - start
    latencies.sort()
    pct = lambda p: round(latencies[min(len(latencies) - 1, int(p * len(latencies)))], 1)  # noqa: E731
    return {"requests": total, "concurrency": concurrency, "errors": errors, "throughput_rps": round(total / wall, 1),
            "p50_ms": pct(0.50), "p95_ms": pct(0.95), "p99_ms": pct(0.99), "mean_ms": round(statistics.mean(latencies), 1)}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("base_url")
    ap.add_argument("--sroie", type=Path, help="SROIE data/ folder; receipts are replayed as request bodies")
    ap.add_argument("--requests", type=int, default=1000)
    ap.add_argument("--concurrency", type=int, default=16)
    args = ap.parse_args()
    texts = ([rebuild_text(p) for p in sorted((args.sroie / "box").glob("*.csv"))] if args.sroie
             else ["TESCO STORES SDN BHD\nDATE 01/02/2019\nMILK 6.50\nTOTAL 12.30"])
    print(asyncio.run(run(args.base_url, texts, args.requests, args.concurrency)))


if __name__ == "__main__":
    main()
