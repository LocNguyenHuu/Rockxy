#!/usr/bin/env python3

import json
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "usage: normalize_identifier_set_json.py '<expected identifiers>' '<actual json array>'",
            file=sys.stderr,
        )
        return 1

    expected = sorted(set(sys.argv[1].split()))
    actual = sorted(set(json.loads(sys.argv[2])))
    payload = {
        "expected": expected,
        "actual": actual,
        "missing": sorted(set(expected) - set(actual)),
        "extra": sorted(set(actual) - set(expected)),
    }
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
