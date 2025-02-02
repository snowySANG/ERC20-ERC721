// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Token {
    string public name; // 代币名称
    string public symbol; // 代币符号
    uint8 public decimals; // 代币小数位数
    uint256 public totalSupply; // 总供应量

    // 存储每个地址的代币余额
    mapping(address => uint256) public balanceOf;

    // 存储授权的代币转账额度
    mapping(address => mapping(address => uint256)) public allowance;

    // Transfer 事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Approval 事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // 构造函数，初始化代币信息和发行的初始供应量
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply); // 创建代币时触发 Transfer 事件
    }

    // 转账函数
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[msg.sender] >= _value, "ERC20: insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value); // 触发 Transfer 事件

        return true;
    }

    // 授权转账函数
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); // 触发 Approval 事件

        return true;
    }

    // 从授权的地址转账函数
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[_from] >= _value, "ERC20: insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "ERC20: allowance exceeded");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value); // 触发 Transfer 事件

        return true;
    }

    // 查询剩余授权额度
    function allowance_remain(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

     // 增加授权额度
    function add_allowance(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "ERC20: add allowance to the zero address");

        allowance[msg.sender][_spender] += _value; // 增加授权额度
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]); // 触发 Approval 事件

        return true;
    }

    // 减少授权额度
    function subtract_allowance(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "ERC20: subtract allowance to the zero address");
        require(allowance[msg.sender][_spender] >= _value, "ERC20: insufficient allowance");

        allowance[msg.sender][_spender] -= _value; // 减少授权额度
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]); // 触发 Approval 事件

        return true;
    }

}
