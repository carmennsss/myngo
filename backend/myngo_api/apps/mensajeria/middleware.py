from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from rest_framework.authtoken.models import Token
from urllib.parse import parse_qs

@database_sync_to_async
def get_user(token_key):
    try:
        token = Token.objects.get(key=token_key)
        return token.user
    except Token.DoesNotExist:
        return AnonymousUser()

class TokenAuthMiddleware:
    """
    Custom middleware that takes a token from the query string and authenticates the user.
    Example: ws://127.0.0.1:8000/ws/chat/1/?token=...
    """

    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        query_string = parse_qs(scope['query_string'].decode())
        token_key = query_string.get('token')
        
        if token_key:
            scope['user'] = await get_user(token_key[0])
        else:
            scope['user'] = AnonymousUser()
            
        return await self.inner(scope, receive, send)
