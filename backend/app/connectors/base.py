from abc import ABC, abstractmethod
from typing import Any

from pydantic import BaseModel, Field


class ConnectorMatch(BaseModel):
    source_name: str
    source_url: str

    matched_name: str | None = None
    matched_phone: str | None = None
    matched_email: str | None = None
    matched_address: str | None = None

    confidence_score: int = Field(
        ge=0,
        le=100,
    )

    status: str = "possible_match"


class BaseConnector(ABC):
    name: str
    enabled: bool = True

    @abstractmethod
    async def search(
        self,
        profile: dict[str, Any],
    ) -> list[ConnectorMatch]:
        """Search one supported source for possible profile matches."""
        raise NotImplementedError