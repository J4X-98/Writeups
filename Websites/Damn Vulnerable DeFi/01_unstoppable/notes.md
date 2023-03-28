totalAssets() seems kind of sketchy
- assembly is checking for the reentrancy flag

mulWadUp() in flashFee() seems a bit strange, but safe at the first look



1000000000000000000000000
10000000000000000000
999999999999999999999999


Ways to get it to revert:

amount == 0 
- Not Doable

asset != _token
- Not Doable

convertToShares(totalSupply) != totalAssets();
- Probably the way to go

safeTransfer(borrower) reverts


receiver.onFlashLoan() != keccak256("IERC3156FlashBorrower.onFlashLoan")
- maybe breakable

safeTransferFrom() reverts
- Make fee not 0

safeTransfer(fee) reverts.
- Change fee receiver and make the fallback an revert