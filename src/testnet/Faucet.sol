// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface PsmLike {
    function dai() external view returns (address);
    function gemJoin() external view returns (address);
    function sellGem(address usr, uint256 gemAmt) external;
}

interface GemJoinLike {
    function gem() external view returns (address);
}

interface TokenLike {
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function mint(address, uint256) external;
}

interface MakerFaucetLike {
    function amt(address) external view returns (uint256);
    function gulp(address gem) external;
}

contract GulpProxy {
    function gulp(MakerFaucetLike faucet, TokenLike gem, address to) external {
        faucet.gulp(address(gem));
        gem.transfer(to, gem.balanceOf(address(this)));
    }
}

contract Faucet {

    PsmLike public immutable psm;
    TokenLike public immutable dai;
    TokenLike public immutable gem;
    MakerFaucetLike public immutable makerFaucet;

    constructor(address _makerFaucet, address _psm) {
        psm = PsmLike(_psm);
        dai = TokenLike(psm.dai());
        gem = TokenLike(GemJoinLike(psm.gemJoin()).gem());
        makerFaucet = MakerFaucetLike(_makerFaucet);

        gem.approve(psm.gemJoin(), type(uint256).max);
    }

    function mint(address token, uint256 amount) external {
        if (token == address(dai)) {
            GulpProxy proxy = new GulpProxy();
            proxy.gulp(makerFaucet, gem, address(this));
            psm.sellGem(msg.sender, gem.balanceOf(address(this)));
        } else if (makerFaucet.amt(token) > 0) {
            GulpProxy proxy = new GulpProxy();
            proxy.gulp(makerFaucet, TokenLike(token), msg.sender);
        } else {
            TokenLike(token).mint(msg.sender, amount);
        }
    }

}