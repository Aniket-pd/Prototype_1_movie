#!/usr/bin/env python3
"""Tiny server-authoritative Sync Table backend for the two-simulator demo."""

from copy import deepcopy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import sqlite3
import threading
from urllib.parse import urlparse


HOST = os.environ.get("SYNC_TABLE_HOST", "127.0.0.1")
PORT = int(os.environ.get("SYNC_TABLE_PORT", "8787"))
ROOT = Path(__file__).resolve().parent.parent
DB_PATH = Path(os.environ.get("SYNC_TABLE_DB", ROOT / ".build" / "sync-table-demo.sqlite3"))
DB_PATH.parent.mkdir(parents=True, exist_ok=True)
database = sqlite3.connect(DB_PATH, check_same_thread=False)
database.execute(
    "CREATE TABLE IF NOT EXISTS sync_tables (table_id TEXT PRIMARY KEY, snapshot TEXT NOT NULL)"
)
database.commit()
lock = threading.Lock()

def load_table(table_id):
    row = database.execute(
        "SELECT snapshot FROM sync_tables WHERE table_id = ?", (table_id,)
    ).fetchone()
    return json.loads(row[0]) if row else None


def save_table(table_id, snapshot):
    database.execute(
        """
        INSERT INTO sync_tables(table_id, snapshot) VALUES (?, ?)
        ON CONFLICT(table_id) DO UPDATE SET snapshot = excluded.snapshot
        """,
        (table_id, json.dumps(snapshot, separators=(",", ":"))),
    )
    database.commit()


def mutate(table_id, action):
    kind = action.get("type")
    with lock:
        existing_state = load_table(table_id)
        if kind in ("bootstrap", "reset"):
            if kind == "bootstrap" and existing_state is not None:
                return deepcopy(existing_state)
            snapshot = deepcopy(action["snapshot"])
            snapshot["revision"] = (existing_state or {}).get("revision", 0) + 1
            save_table(table_id, snapshot)
            return deepcopy(snapshot)

        if existing_state is None:
            raise KeyError(table_id)

        state = existing_state
        if kind == "stage":
            state["stage"] = action["stage"]
        elif kind == "join":
            role = action["role"]
            state["table"]["hostConnected" if role == "host" else "partnerConnected"] = True
            state["partnerJoined"] = state["table"].get("partnerConnected", False)
        elif kind == "selectPair":
            state["table"]["selectedPair"] = action["pair"]
            state["table"]["hostCart"]["items"] = []
            state["table"]["partnerCart"]["items"] = []
        elif kind == "orderingMode":
            state["table"]["orderingMode"] = action["mode"]
            state["table"]["selectedPair"] = None
            state["table"]["hostCart"]["items"] = []
            state["table"]["partnerCart"]["items"] = []
            state["table"]["paymentDecision"] = {
                "confirmedBy": [],
                "payerID": None,
                "arrangement": None,
            }
        elif kind == "cart":
            cart_key = "hostCart" if action["role"] == "host" else "partnerCart"
            items = state["table"][cart_key]["items"]
            item = action["item"]
            existing = next((entry for entry in items if entry["menuItem"]["id"] == item["id"]), None)
            if existing:
                existing["quantity"] += action["delta"]
                if existing["quantity"] <= 0:
                    items.remove(existing)
            elif action["delta"] > 0:
                items.append({"menuItem": item, "quantity": action["delta"]})
        elif kind == "ready":
            key = "hostReady" if action["role"] == "host" else "partnerReady"
            state["table"][key] = action["value"]
        elif kind == "payment":
            state["table"]["paymentDecision"] = action["payment"]
        elif kind == "confirmPayment":
            confirmations = state["table"]["paymentDecision"].setdefault("confirmedBy", [])
            participant_id = action["participantID"]
            if participant_id not in confirmations:
                confirmations.append(participant_id)
        elif kind == "orders":
            state["table"]["orders"] = action["orders"]
        elif kind == "event":
            event = action["event"]
            events = state["events"]
            if not any(existing["id"] == event["id"] for existing in events):
                events.insert(0, event)
                del events[20:]
        elif kind == "memory":
            state["table"]["memory"] = action["memory"]
        elif kind == "readyToEat":
            key = "hostReadyToEat" if action["role"] == "host" else "partnerReadyToEat"
            state[key] = action["value"]
        elif kind == "countdown":
            state["countdown"] = action.get("countdown")
        else:
            raise ValueError(f"unknown action: {kind}")

        state["revision"] += 1
        save_table(table_id, state)
        return deepcopy(state)


class Handler(BaseHTTPRequestHandler):
    server_version = "SyncTableDemo/1.0"

    def do_GET(self):
        parts = urlparse(self.path).path.strip("/").split("/")
        if parts == ["health"]:
            with lock:
                count = database.execute("SELECT COUNT(*) FROM sync_tables").fetchone()[0]
            return self.respond(200, {"status": "ok", "tables": count, "database": str(DB_PATH)})
        if len(parts) == 2 and parts[0] == "tables":
            with lock:
                state = load_table(parts[1])
            return self.respond(200, state) if state else self.respond(404, {"error": "not found"})
        self.respond(404, {"error": "not found"})

    def do_POST(self):
        parts = urlparse(self.path).path.strip("/").split("/")
        if len(parts) != 3 or parts[0] != "tables" or parts[2] != "actions":
            return self.respond(404, {"error": "not found"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            action = json.loads(self.rfile.read(length))
            self.respond(200, mutate(parts[1], action))
        except KeyError:
            self.respond(404, {"error": "table not found"})
        except (ValueError, TypeError, json.JSONDecodeError) as error:
            self.respond(400, {"error": str(error)})

    def do_DELETE(self):
        parts = urlparse(self.path).path.strip("/").split("/")
        if parts == ["tables"]:
            with lock:
                database.execute("DELETE FROM sync_tables")
                database.commit()
            return self.respond(200, {"status": "all tables reset"})
        if len(parts) != 2 or parts[0] != "tables":
            return self.respond(404, {"error": "not found"})
        with lock:
            database.execute("DELETE FROM sync_tables WHERE table_id = ?", (parts[1],))
            database.commit()
        self.respond(200, {"status": "reset"})

    def respond(self, status, payload):
        body = json.dumps(payload, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, pattern, *args):
        if "__connection_probe__" in (args[0] if args else ""):
            return
        print(f"[sync-table] {self.address_string()} {pattern % args}", flush=True)


if __name__ == "__main__":
    print(f"Sync Table demo backend listening on http://{HOST}:{PORT} using {DB_PATH}", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
