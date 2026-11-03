"""Firebase ID-token verification.

The Flutter app already signs users in with Firebase Auth, so it sends the
user's ID token as a bearer token and the API verifies its signature, audience
and expiry against Google's public keys. No service-account key is needed.
"""
from dataclasses import dataclass

import google.auth.transport.requests
from fastapi import Depends, Header, HTTPException, status
from google.oauth2 import id_token

from .config import Settings, get_settings

_request = google.auth.transport.requests.Request()


@dataclass(frozen=True)
class User:
    uid: str
    email: str | None = None


def verify_firebase_token(token: str, project_id: str) -> User:
    claims = id_token.verify_firebase_token(token, _request, audience=project_id)
    if not claims or claims.get("iss") != f"https://securetoken.google.com/{project_id}":
        raise ValueError("wrong issuer")
    return User(uid=claims["sub"], email=claims.get("email"))


def current_user(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> User:
    if settings.auth_mode == "disabled":
        return User(uid="local-dev")
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token", {"WWW-Authenticate": "Bearer"})
    try:
        return verify_firebase_token(authorization.split(" ", 1)[1].strip(), settings.firebase_project_id)
    except Exception:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid or expired token", {"WWW-Authenticate": "Bearer"})
