from slowapi import Limiter
from slowapi.util import get_remote_address

# Create limiter instance
limiter = Limiter(key_func=lambda request: request.state.user.get("userId", get_remote_address(request)))
