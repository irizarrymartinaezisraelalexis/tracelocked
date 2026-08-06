from typing import Any

from app.scan_engine.base import BaseConnector, ScanMatch


class DemoConnector(BaseConnector):
    name = "Demo People Search"

    async def search(self, profile: dict[str, Any]) -> list[ScanMatch]:
        return [
            ScanMatch(
                source_name=self.name,
                source_url="https://example.com/demo-profile",
                matched_name=f"{profile['first_name']} {profile['last_name']}",
                matched_phone=profile["phone_numbers"][0]
                if profile.get("phone_numbers")
                else None,
                matched_email=profile["email_addresses"][0]
                if profile.get("email_addresses")
                else None,
                matched_address=(
                    f"{profile['current_address']['street']}, "
                    f"{profile['current_address']['city']}, "
                    f"{profile['current_address']['state']} "
                    f"{profile['current_address']['postal_code']}"
                ),
                confidence_score=95,
                status="possible_match",
            )
        ]