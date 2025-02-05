// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC165 接口，用于检查合约是否支持某个接口
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// ERC721 接口，定义了 ERC721 标准的基本功能
interface ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// MyERC721 合约，实现了 ERC721 接口
contract MyERC721 is ERC721 {
    string public name = "MyERC721Token";
    string public symbol = "M721";

    uint256 private _tokenIdCounter;  // 用于生成新的 tokenId
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {}

    // ERC165: 检查合约是否支持某个接口
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(ERC721).interfaceId || interfaceID == type(ERC165).interfaceId;
    }

    // 获取某个地址拥有的 NFT 数量
    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }

    // 获取某个 NFT 的所有者
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        address owner = _owners[_tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    // mint 新的 NFT
    function mint(address _to) external {
        require(_to != address(0), "ERC721: mint to the zero address");

        _tokenIdCounter++;  // 增加 tokenId 计数器
        uint256 newTokenId = _tokenIdCounter;  // 获取新的 tokenId

        // 将新 tokenId 的所有权分配给 _to 地址
        _owners[newTokenId] = _to;
        _balances[_to] += 1;

        // 触发 Transfer 事件（从地址 0 表示创建）
        emit Transfer(address(0), _to, newTokenId);
    }

    // 安全转移 NFT，附带数据
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external override {
        if (data.length == 0)
            require(_checkOnERC721Received(_from, _to, _tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");

        transferFrom(_from, _to, _tokenId);
    }

    // 标准转移 NFT
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        address owner = _owners[_tokenId];
        require(owner == _from, "ERC721: transfer of token that is not owned");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(_tokenId);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    // 授权某个地址可以转移特定的 NFT
    function approve(address _approved, uint256 _tokenId) external override {
        address owner = _owners[_tokenId];
        require(msg.sender == owner, "ERC721: approve caller is not token owner");

        _tokenApprovals[_tokenId] = _approved;

        emit Approval(owner, _approved, _tokenId);
    }

    // 授权或取消授权某个地址管理所有 NFT
    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // 获取某个 NFT 的授权地址
    function getApproved(uint256 _tokenId) external view override returns (address) {
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
        if (_to.code.length > 0) {
            try ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
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
