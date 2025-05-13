# pip3 install web.py smartrent.py
# 
# Run this program like: python this.py 3093
# Usage: curl "http://localhost:3093/_PLACEHOLDER_APIK___/lock"
# Usage: curl "http://localhost:3093/_PLACEHOLDER_APIK___/unlock"

import asyncio
from smartrent import async_login

### sample:
# async def main():
#     api = await async_login('bensong.liu@microsoft.com', '_PLACEHOLDER_PASS___')
# 
#     lock = api.get_locks()[0]
#     print(lock)
#     locked = lock.get_locked()
#     print(locked)
#     await lock.async_set_locked(False)
# 
#     # if not locked:
#     #     await lock.async_set_locked(True)
# 
# asyncio.run(main())

def get_api():
    async def _wrapped():
        return await async_login('bensong.liu@microsoft.com', '_PLACEHOLDER_PASS___')
    return asyncio.run(_wrapped())

def set_locked(lock_obj, true_or_false):
    async def _wrapped2(l, tf):
        return await l.async_set_locked(tf)
    return asyncio.run(_wrapped2(lock_obj, true_or_false))

api = get_api()
lock = api.get_locks()[0]
def lock_or_unlock(lockit_or_not):
    # Param: True for lock, False for unlock
    # Return: message
    locked = lock.get_locked()
    msg = "locked" if lockit_or_not else "unlocked"
    if lockit_or_not == locked:
        return "Door: Already " + msg
    res = set_locked(lock, lockit_or_not)
    print("DEBUG: ", res)
    return "Door: Successfully " + msg

import web

urls = (
    '/(.*)', 'hello'
)
app = web.application(urls, globals())

class hello:
    def GET(self, uri):
        if not uri.startswith('_PLACEHOLDER_APIK___'):
            return "Wrong API key"
        try:
            action = uri.split('/')[1].lower()
            if action == "lock":
                lockit_or_not = True
            elif action == "unlock":
                lockit_or_not = False
            else:
                return "Wrong API usage. Expect lock or unlock"
            return lock_or_unlock(lockit_or_not)
        except Exception as e:
            return "API Error: " + str(e)

if __name__ == "__main__":
    app.run()
