// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import './token.sol';
import "hardhat/console.sol";


contract TokenExchange is Ownable {
    string public exchange_name = 'Boba_Ex';

    address tokenAddr = 0xd3873FDF150b3fFFb447d3701DFD234DF452F367;                                  // TODO: paste token contract address here
    Token public token = Token(tokenAddr);                                

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;

    uint private token_reward = 0;
    uint private eth_reward = 0;

    mapping(address => uint) private lps; 
     
    // Needed for looping through the keys of the lps mapping
    address[] private lp_providers;                     

    // liquidity rewards
    uint private swap_fee_numerator = 5;                // TODO Part 5: Set liquidity providers' returns.
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    constructor() {}
    

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens)
        external
        payable
        onlyOwner
    {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require (token_reserves == 0, "Token reserves was not 0");
        require (eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require (msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(amountTokens <= tokenSupply, "Not have enough tokens to create the pool");
        require (amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;
    }

    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(index < lp_providers.length, "specified index is larger than the number of lps");
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================
    
    /* ========================= Liquidity Provider Functions =========================  */ 

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(uint max_exchange_rate, uint min_exchange_rate) 
        external 
        payable
    {
        /******* TODO: Implement this function *******/
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
        // console.log("k: ", k);
        // console.log("eth_reward: ", eth_reward);
        // console.log("token_reward: ", token_reward);

        eth_reserves += eth_reward;
        token_reserves += token_reward;
        eth_reward = 0;
        token_reward = 0;

        require(msg.value > 0, "Invalid amount of ETH to add.");
        // console.log("eth_reserves * 100 / token_reserves: ", eth_reserves * 100 / token_reserves);
        require(eth_reserves * 100 / token_reserves <= max_exchange_rate, "Exceed the max_exchange_rate of token.");
        require(eth_reserves * 100 / token_reserves >= min_exchange_rate, "Fall below the min_exchange_rate of token.");

        // Transfer the equivalent amount of tokens. transfer eth?
        uint token_amount = msg.value * token_reserves / eth_reserves;
        // console.log("token_amount: ", token_amount);
        require(token.transferFrom(msg.sender, address(this), token_amount) == true, "Cannot transfer token from the user");
        
        // Update the exchange state.
        uint prev_eth_reserves = eth_reserves;
        eth_reserves += msg.value;
        token_reserves += token_amount;
        k = token_reserves * eth_reserves;
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
        // console.log("k: ", k);

        // Update the fraction of each liquidity provider.
        // console.log("lps[msg.sender] before: ", lps[msg.sender]);
        lps[msg.sender] = (lps[msg.sender] * prev_eth_reserves / 10000 + msg.value) * 10000 / eth_reserves;
        // console.log("lps[msg.sender] after: ", lps[msg.sender]);
        bool is_in_array = false;
        uint arrayLength = lp_providers.length;
        for (uint i = 0; i < arrayLength; i++) {
            // console.log("lps i ", i);
            if (lp_providers[i] == msg.sender) {
                is_in_array = true;
                continue;
            }
            // console.log("lps[lp_providers[i]] before: ", lps[lp_providers[i]]);
            lps[lp_providers[i]] = lps[lp_providers[i]] * prev_eth_reserves / eth_reserves;
            // console.log("lps[lp_providers[i]] after: ", lps[lp_providers[i]]);
        }
        // console.log("lp_providers.length before push: ", lp_providers.length);
        if (!is_in_array) {
            lp_providers.push(msg.sender);
        }
        // console.log("lp_providers.length after push: ", lp_providers.length);
    }


    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(uint amountETH, uint max_exchange_rate, uint min_exchange_rate)
        public 
        payable
    {
        /******* TODO: Implement this function *******/
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
        // console.log("k: ", k);
        // console.log("eth_reward: ", eth_reward);
        // console.log("token_reward: ", token_reward);

        eth_reserves += eth_reward;
        token_reserves += token_reward;
        eth_reward = 0;
        token_reward = 0;

        require(amountETH > 0, "Invalid amount of ETH to remove.");
        require(amountETH < eth_reserves, "Not have enough ETH in the pool to remove.");
        // console.log("eth_reserves * 100 / token_reserves: ", eth_reserves * 100 / token_reserves);
        require(eth_reserves * 100 / token_reserves <= max_exchange_rate, "Exceed the max_exchange_rate of token.");
        require(eth_reserves * 100 / token_reserves >= min_exchange_rate, "Fall below the min_exchange_rate of token.");

        uint eth_amount_user = lps[msg.sender] * eth_reserves / 10000;
        require(amountETH <= eth_amount_user, "User not have enough ETH to remove.");

        // Transfer ETH of amountETH and the equivalent amount of tokens to the user.
        uint prev_eth_reserves = eth_reserves;
        uint token_amount = amountETH * token_reserves / eth_reserves;
        // console.log("token_amount: ", token_amount);
        payable(msg.sender).transfer(amountETH);
        require(token.transfer(msg.sender, token_amount) == true, "Cannot transfer token to the user.");

        // Update the exchange state.
        eth_reserves -= amountETH;
        token_reserves -= token_amount;
        k = token_reserves * eth_reserves;
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
        // console.log("k: ", k);

        // Update the fraction of each liquidity provider.
        // console.log("lps[msg.sender] before: ", lps[msg.sender]);
        lps[msg.sender] = (eth_amount_user - amountETH) * 10000 / eth_reserves;
        // console.log("lps[msg.sender] after: ", lps[msg.sender]);
        uint index_to_remove = lp_providers.length;
        uint arrayLength = lp_providers.length;
        for (uint i = 0; i < arrayLength; i++) {
            // console.log("lps i ", i);
            if (lp_providers[i] == msg.sender) {
                index_to_remove = i;
                continue;
            }
            // console.log("lps[lp_providers[i]] before: ", lps[lp_providers[i]]);
            lps[lp_providers[i]] = lps[lp_providers[i]] * prev_eth_reserves / eth_reserves;
            // console.log("lps[lp_providers[i]] after: ", lps[lp_providers[i]]);
        }

        // console.log("lp_providers.length before: ", lp_providers.length);
        if (lps[msg.sender] == 0) {
            removeLP(index_to_remove);
        }
        // console.log("lp_providers.length after: ", lp_providers.length);
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(uint max_exchange_rate, uint min_exchange_rate)
        external
        payable
    {
        /******* TODO: Implement this function *******/
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
        // console.log("k: ", k);
        // console.log("eth_reward: ", eth_reward);
        // console.log("token_reward: ", token_reward);

        eth_reserves += eth_reward;
        token_reserves += token_reward;
        eth_reward = 0;
        token_reward = 0;

        uint eth_amount = lps[msg.sender] * eth_reserves / 10000;
        uint token_amount = lps[msg.sender] * token_reserves / 10000;
        require(eth_amount < eth_reserves, "Not have enough ETH in the pool to remove.");
        require(token_amount < token_reserves, "Not have enough token in the pool to remove.");
        
        // console.log("eth_reserves * 100 / token_reserves: ", eth_reserves * 100 / token_reserves);
        require(eth_reserves * 100 / token_reserves <= max_exchange_rate, "Exceed the max_exchange_rate of token.");
        require(eth_reserves * 100 / token_reserves >= min_exchange_rate, "Fall below the min_exchange_rate of token.");

        // Transfer all their ETH and the equivalent amount of tokens to the user.
        uint prev_eth_reserves = eth_reserves;
        payable(msg.sender).transfer(eth_amount);
        require(token.transfer(msg.sender, token_amount) == true, "Cannot transfer token to the user.");
        
        // Update the exchange state.
        eth_reserves -= eth_amount;
        token_reserves -= token_amount;
        k = token_reserves * eth_reserves;
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
        // console.log("k: ", k);

        // Update the fraction of each liquidity provider.
        uint index_to_remove = lp_providers.length;
        uint arrayLength = lp_providers.length;
        for (uint i = 0; i < arrayLength; i++) {
            // console.log("lps i ", i);
            if (lp_providers[i] == msg.sender) {
                index_to_remove = i;
                continue;
            }
            // console.log("lps[lp_providers[i]] before: ", lps[lp_providers[i]]);
            lps[lp_providers[i]] = lps[lp_providers[i]] * prev_eth_reserves / eth_reserves;
            // console.log("lps[lp_providers[i]] after: ", lps[lp_providers[i]]);
        }
        // console.log("lps[msg.sender] before: ", lps[msg.sender]);
        lps[msg.sender] = 0;
        // console.log("lps[msg.sender] after: ", lps[msg.sender]);
        // console.log("lp_providers.length before: ", lp_providers.length);
        removeLP(index_to_remove);
        // console.log("lp_providers.length after: ", lp_providers.length);
    }
    /***  Define additional functions for liquidity fees here as needed ***/


    /* ========================= Swap Functions =========================  */ 

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(uint amountTokens, uint max_exchange_rate)
        external 
        payable
    {
        /******* TODO: Implement this function *******/
        // console.log("token_reserves * 100 / eth_reserves: ", token_reserves * 100 / eth_reserves);
        require(token_reserves * 100 / eth_reserves <= max_exchange_rate, "Exceed the max_exchange_rate of ETH.");

        // Update token reserve and eth reserve after swap.
        // Deduct swap reward from token amount.
        uint swap_reward = amountTokens * swap_fee_numerator / swap_fee_denominator;
        // console.log("swap_reward: ", swap_reward);
        // console.log("token_reward: ", token_reward);
        token_reward += swap_reward;
        uint next_token_reserve = token_reserves + amountTokens - swap_reward;
        uint next_eth_reserve = k / next_token_reserve;
        // console.log("next_token_reserve: ", next_token_reserve);
        // console.log("next_eth_reserve: ", next_eth_reserve);
        require(next_eth_reserve >= 1, "Not have enough ETH in the pool to swap.");
        
        // Transfer eth and token.
        uint eth_amount = eth_reserves - next_eth_reserve;
        // console.log("eth_amount: ", eth_amount);
        payable(msg.sender).transfer(eth_amount);
        require(token.transferFrom(msg.sender, address(this), amountTokens) == true, "Cannot transfer token from the user.");

        // Update the exchange state.
        eth_reserves -= eth_amount;
        token_reserves = next_token_reserve;
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
    }



    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate)
        external
        payable 
    {
        /******* TODO: Implement this function *******/
        // console.log("eth_reserves * 100 / token_reserves: ", eth_reserves * 100 / token_reserves);
        require(eth_reserves * 100 / token_reserves <= max_exchange_rate, "Exceed the max_exchange_rate of token.");

        // Update token reserve and eth reserve after swap.
        // Deduct swap reward from eth amount.
        uint swap_reward = msg.value * swap_fee_numerator / swap_fee_denominator;
        // console.log("swap_reward: ", swap_reward);
        // console.log("eth_reward: ", eth_reward);
        eth_reward += swap_reward;
        uint next_eth_reserve = eth_reserves + msg.value - swap_reward;
        uint next_token_reserve = k / next_eth_reserve;
        // console.log("next_token_reserve: ", next_token_reserve);
        // console.log("next_eth_reserve: ", next_eth_reserve);
        require(next_token_reserve >= 1, "Not have enough token in the pool to swap.");

        // Transfer token.
        uint token_amount = token_reserves - next_token_reserve;
        // console.log("token_amount: ", token_amount);
        require(token.transfer(msg.sender, token_amount) == true, "Cannot transfer token to the user.");

        // Update the exchange state.
        eth_reserves = next_eth_reserve;
        token_reserves -= token_amount;
        // console.log("eth_reserves: ", eth_reserves);
        // console.log("token_reserves: ", token_reserves);
    }
}