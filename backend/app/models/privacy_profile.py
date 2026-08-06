from pydantic import BaseModel, EmailStr, Field


class Address(BaseModel):
    street: str
    city: str
    state: str = Field(min_length=2, max_length=2)
    postal_code: str


class PrivacyProfileCreate(BaseModel):
    first_name: str
    last_name: str
    email_addresses: list[EmailStr]
    phone_numbers: list[str]
    current_address: Address
    previous_addresses: list[Address] = []
    date_of_birth: str | None = None


class PrivacyProfileResponse(PrivacyProfileCreate):
    profile_id: str
    status: str