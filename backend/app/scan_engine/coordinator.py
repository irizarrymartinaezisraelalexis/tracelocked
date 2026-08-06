from typing import Any

from app.scan_engine.base import ScanMatch
from app.scan_engine.demo_connector import DemoConnector


class ScanCoordinator:
    def __init__(self) -> None:
        self.connectors = [
            DemoConnector(),
        ]

    async def run_scan(
        self,
        profile: dict[str, Any],
    ) -> list[ScanMatch]:
        matches: list[ScanMatch] = []

        for connector in self.connectors:
            connector_matches = await connector.search(profile)
            matches.extend(connector_matches)

        return matches