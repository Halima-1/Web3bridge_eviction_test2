// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SigLib {

    error InvalidSignature();

    function recover(bytes32 digest, bytes memory sig)
        internal
        pure
        returns (address)
    {
        if (sig.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig,32))
            s := mload(add(sig,64))
            v := byte(0, mload(add(sig,96)))
        }

        return ecrecover(digest, v, r, s);
    }
}