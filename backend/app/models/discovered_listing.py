from pydantic import BaseModel, Field


class DiscoveredListingCreate(BaseModel):
    source_key: str = Field(
        min_length=1,
        max_length=100,
    )

    source_url: str = Field(
        min_length=1,
        max_length=2000,
    )

    matched_name: str | None = None
    matched_phone: str | None = None
    matched_email: str | None = None
    matched_address: str | None = None