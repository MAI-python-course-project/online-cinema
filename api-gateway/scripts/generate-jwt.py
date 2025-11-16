#!/usr/bin/env python3
"""
JWT Token Generator for API Gateway Testing

Usage:
    python generate-jwt.py --user-id USER_ID --email EMAIL
    python generate-jwt.py --user-id 123 --email user@example.com --ttl 3600
"""

import jwt
import time
import argparse
from datetime import datetime, timedelta


def generate_jwt(
    user_id: str,
    email: str,
    issuer: str = "cinema-issuer",
    secret: str = "your-super-secret-jwt-key-change-in-production",
    ttl_seconds: int = 3600
) -> str:
    """
    Generate JWT token for testing

    Args:
        user_id: User ID
        email: User email
        issuer: JWT issuer (must match Kong configuration)
        secret: JWT secret (must match Kong configuration)
        ttl_seconds: Time to live in seconds

    Returns:
        JWT token string
    """
    now = int(time.time())

    payload = {
        'iss': issuer,
        'sub': user_id,
        'email': email,
        'iat': now,
        'exp': now + ttl_seconds,
    }

    token = jwt.encode(payload, secret, algorithm='HS256')

    return token


def decode_jwt(token: str, secret: str = "your-super-secret-jwt-key-change-in-production"):
    """
    Decode and verify JWT token

    Args:
        token: JWT token
        secret: JWT secret

    Returns:
        Decoded payload
    """
    try:
        payload = jwt.decode(token, secret, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        return {"error": "Token expired"}
    except jwt.InvalidTokenError as e:
        return {"error": f"Invalid token: {str(e)}"}


def main():
    parser = argparse.ArgumentParser(description='Generate JWT token for API Gateway')
    parser.add_argument('--user-id', required=True, help='User ID')
    parser.add_argument('--email', required=True, help='User email')
    parser.add_argument('--issuer', default='cinema-issuer', help='JWT issuer')
    parser.add_argument('--secret', default='your-super-secret-jwt-key-change-in-production', help='JWT secret')
    parser.add_argument('--ttl', type=int, default=3600, help='Time to live in seconds (default: 3600)')
    parser.add_argument('--decode', help='Decode existing token')

    args = parser.parse_args()

    if args.decode:
        # Decode mode
        payload = decode_jwt(args.decode, args.secret)
        print("\n=== Decoded JWT ===")
        print(f"Payload: {payload}")

        if 'exp' in payload:
            exp_time = datetime.fromtimestamp(payload['exp'])
            print(f"Expires at: {exp_time}")

            if payload['exp'] > time.time():
                print("Status: ✅ Valid")
            else:
                print("Status: ❌ Expired")
    else:
        # Generate mode
        token = generate_jwt(
            user_id=args.user_id,
            email=args.email,
            issuer=args.issuer,
            secret=args.secret,
            ttl_seconds=args.ttl
        )

        print("\n=== Generated JWT Token ===")
        print(f"Token: {token}")
        print("\n=== Payload ===")

        payload = decode_jwt(token, args.secret)
        for key, value in payload.items():
            if key == 'exp' or key == 'iat':
                dt = datetime.fromtimestamp(value)
                print(f"{key}: {value} ({dt})")
            else:
                print(f"{key}: {value}")

        print("\n=== Usage Examples ===")
        print(f"\n# Authorization Header:")
        print(f'curl -H "Authorization: Bearer {token}" http://localhost/api/v1/users/me')

        print(f"\n# Query Parameter:")
        print(f'curl "http://localhost/api/v1/users/me?jwt={token}"')

        print(f"\n# Cookie:")
        print(f'curl --cookie "jwt={token}" http://localhost/api/v1/users/me')


if __name__ == '__main__':
    main()
