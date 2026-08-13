from pydantic import BaseModel, Field


class ScanTaskStatusUpdate(BaseModel):
    status: str = Field(
        min_length=1,
        max_length=50,
    )

    result_url: str | None = Field(
        default=None,
        max_length=2000,
    )

    confidence_score: float | None = Field(
        default=None,
        ge=0.0,
        le=1.0,
    )