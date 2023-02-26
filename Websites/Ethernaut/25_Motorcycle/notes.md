### Motorbike 0xf5Fd286fAd1BEB6b99045e7507c0ff4275272ad3
- getAdressSlot seems kind of sketchy.


### Engine 0xf7C50428803E0a8286Bdf8C4dDa7FcE26616C097

Attack:
The initialization only happens in the context of the proxy, is we directly call initalize of the engine we can become the owner.

We then just overwrite the implementation with our own engine one that has a selfdestruct function and kill this one, as the call in the function _upgradeToAndCall is a delegatecall, if we call the kill fucntion in our engine, it actually kills the real engine.

