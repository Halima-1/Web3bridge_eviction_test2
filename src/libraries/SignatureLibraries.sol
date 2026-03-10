// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SignatureLibraries {

    error InvalidSignature();

    function recover(bytes32 digest, bytes memory sig) internal pure returns(address) {

        if(sig.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig,32))
            s := mload(add(sig,64))
            v := byte(0,mload(add(sig,96)))
        }

        if(uint256(s) > 
           0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        ) revert InvalidSignature();

        if(v != 27 && v != 28) revert InvalidSignature();

        address signer = ecrecover(digest,v,r,s);

        if(signer == address(0)) revert InvalidSignature();

        return signer;
    }
}