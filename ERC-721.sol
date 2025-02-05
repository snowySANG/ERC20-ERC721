// SPDX-License-Identifier: MIT
// 声明代码的许可证类型，这里使用的是 MIT 许可证
pragma solidity ^0.8.0;

// ERC165 接口，用于检查合约是否支持某个接口
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// ERC721 接口，定义了 ERC721 标准的基本功能
interface ERC721 is ERC165 {
    // 事件：当 NFT 的所有权转移时触发
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    // 事件：当某个 NFT 被授权给某个地址时触发
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    // 事件：当某个地址被授权或取消授权管理所有 NFT 时触发
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // 获取某个地址拥有的 NFT 数量
    function balanceOf(address _owner) external view returns (uint256);
    // 获取某个 NFT 的所有者
    function ownerOf(uint256 _tokenId) external view returns (address);
    // 安全转移 NFT，附带数据
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    // 转移 NFT
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    // 授权某个地址可以转移特定的 NFT
    function approve(address _approved, uint256 _tokenId) external;
    // 授权或取消授权某个地址管理所有 NFT
    function setApprovalForAll(address _operator, bool _approved) external;
    // 获取某个 NFT 的授权地址
    function getApproved(uint256 _tokenId) external view returns (address);
    // 检查某个地址是否被授权管理某个所有者的所有 NFT
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// MyERC721 合约，实现了 ERC721 接口
contract MyERC721 is ERC721 {
    // NFT 的名称
    string public name = "Snowy";
    // NFT 的符号
    string public symbol = "Sn";

    // 存储每个 NFT 的所有者
    mapping(uint256 => address) private _owners;
    // 存储每个地址拥有的 NFT 数量
    mapping(address => uint256) private _balances;
    // 存储每个 NFT 的授权地址
    mapping(uint256 => address) private _tokenApprovals;
    // 存储每个地址是否被授权管理另一个地址的所有 NFT
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // 构造函数
    constructor() {}

    // ERC165: 检查合约是否支持某个接口
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        // 支持 ERC721 和 ERC165 接口
        return interfaceID == type(ERC721).interfaceId || interfaceID == type(ERC165).interfaceId;
    }

    // 获取某个地址拥有的 NFT 数量
    function balanceOf(address _owner) external view override returns (uint256) {
        // 检查地址是否为 0 地址
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }

    // 获取某个 NFT 的所有者
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        address owner = _owners[_tokenId];
        // 检查 NFT 是否存在
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    // 安全转移 NFT，附带数据
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external override {
        // 如果数据为空，检查接收方是否是 ERC721Receiver 实现者
        if (data.length == 0)
        require(_checkOnERC721Received(_from, _to, _tokenId,""), "ERC721: transfer to non ERC721Receiver implementer");
    
        // 调用标准转移函数
        transferFrom(_from, _to, _tokenId);
    }

    // 标准转移 NFT
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        // 获取 NFT 的所有者
        address owner = _owners[_tokenId];
        // 检查调用者是否是 NFT 的所有者
        require(owner == _from, "ERC721: transfer of token that is not owned");
        // 检查目标地址是否为 0 地址
        require(_to != address(0), "ERC721: transfer to the zero address");

        // 清除 NFT 的授权
        _clearApproval(_tokenId);

        // 更新所有者余额
        _balances[_from] -= 1;
        _balances[_to] += 1;
        // 更新 NFT 的所有者
        _owners[_tokenId] = _to;

        // 触发 Transfer 事件
        emit Transfer(_from, _to, _tokenId);
    }

    // 授权某个地址可以转移特定的 NFT
    function approve(address _approved, uint256 _tokenId) external override {
        // 获取 NFT 的所有者
        address owner = _owners[_tokenId];
        // 检查调用者是否是 NFT 的所有者
        require(msg.sender == owner, "ERC721: approve caller is not token owner");

        // 设置 NFT 的授权地址
        _tokenApprovals[_tokenId] = _approved;

        // 触发 Approval 事件
        emit Approval(owner, _approved, _tokenId);
    }

    // 授权或取消授权某个地址管理所有 NFT
    function setApprovalForAll(address _operator, bool _approved) external override {
        // 检查操作者地址是否与调用者地址相同
        require(_operator != msg.sender, "ERC721: approve to caller");

        // 设置操作者的授权状态
        _operatorApprovals[msg.sender][_operator] = _approved;

        // 触发 ApprovalForAll 事件
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // 获取某个 NFT 的授权地址
    function getApproved(uint256 _tokenId) external view override returns (address) {
        // 检查 NFT 是否存在
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    // 检查某个地址是否被授权管理某个所有者的所有 NFT
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    // 内部函数：检查 NFT 是否存在
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    // 内部函数：清除 NFT 的授权
    function _clearApproval(uint256 _tokenId) private {
        if (_tokenApprovals[_tokenId] != address(0)) {
            delete _tokenApprovals[_tokenId];
        }
    }

    // 内部函数：检查接收方是否是 ERC721Receiver 实现者
    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        // 检查接收方是否是合约
        if (_to.code.length > 0) {
            try ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                // 检查返回值是否正确
                return retval == ERC721Receiver(_to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// ERC721Receiver 接口，用于接收 ERC721 令牌的合约
interface ERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
