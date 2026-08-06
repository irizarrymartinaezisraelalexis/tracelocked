from abc import ABC, abstractmethod
from typing import Any

from pydantic import BaseModel


class ScanMatch(BaseModel):
    source_name: str
    source_url: str
    matched_name: str | None = None
    matched_phone: str | None = None
    matched_email: str | None = None
    matched_address: str | None = None
    confidence_score: int
    status: str = "possible_match"


class BaseConnector(ABC):
    name: str

    @abstractmethod
    async def search(self, profile: dict[str, Any]) -> list[ScanMatch]:
        """Search one supported source using a privacy profile."""
        raise NotImplementedError