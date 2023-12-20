// SPDX-License-Identifier: MIT

pragma solidity =0.8.12;

contract CellPhoneCompanyContract {
    struct Customer {
        string customerName;
        uint customerBalance;
    }

    struct Product {
        string productName;
        uint productPoints;
        uint amountExchanged;
    }

    address private _contractOwner;

    Product[] public products;

    mapping(address => Customer) private _enrolledCustomers;

    modifier contractOwnerOnly() {
        require(msg.sender == _contractOwner);
        _;
    }

    constructor() {
        _contractOwner = msg.sender;
        Product memory product0 = Product({
            productName: "Watch",
            productPoints: 2,
            amountExchanged: 0
        });
        Product memory product1 = Product({
            productName: "Cellphone",
            productPoints: 5,
            amountExchanged: 0
        });
        Product memory product2 = Product({
            productName: "Computer",
            productPoints: 10,
            amountExchanged: 0
        });
        products.push(product0);
        products.push(product1);
        products.push(product2);
    }

    event ProductExchanged(
        address indexed _customer,
        uint _productIndex,
        uint _dateAndTime
    );

    function enrollCustomer(string memory _customerName) public {
        require(isCustomerNameValid(_customerName), "Name must be informed");
        require(
            !isCustomerValid(getEnrolledCustomerByAddress(msg.sender)),
            "Customer already enrolled"
        );

        Customer memory customer;
        customer.customerName = _customerName;
        customer.customerBalance = 0;

        assert(isCustomerValid(customer));

        _enrolledCustomers[msg.sender] = customer;
    }

    function getEnrolledCustomerByAddress(
        address _customerAddress
    ) public view returns (Customer memory) {
        return _enrolledCustomers[_customerAddress];
    }

    function isCustomerNameValid(
        string memory _customerName
    ) private pure returns (bool) {
        bytes memory tempString = bytes(_customerName);
        return tempString.length > 0;
    }

    function isCustomerBalanceValid(
        uint _customerBalance
    ) private pure returns (bool) {
        return _customerBalance >= 0;
    }

    function isCustomerValid(
        Customer memory _customer
    ) private pure returns (bool) {
        return
            isCustomerNameValid(_customer.customerName) &&
            isCustomerBalanceValid(_customer.customerBalance);
    }

    function payMonthlyBill(uint _totalDueInWei) public payable {
        require(msg.value == _totalDueInWei, "Total payment value is invalid");

        Customer storage customer = _enrolledCustomers[msg.sender];

        require(isCustomerValid(customer), "Customer not enrolled");

        customer.customerBalance += 1;
    }

    function exchangeCustomerPointsByProduct(uint _productIndex) public {
        require(
            _productIndex <= products.length - 1,
            "Product index is not valid"
        );

        Customer storage customer = _enrolledCustomers[msg.sender];

        require(isCustomerValid(customer), "Customer not enrolled");

        Product storage product = products[_productIndex];

        require(
            customer.customerBalance >= product.productPoints,
            "Not enough points to be used"
        );

        customer.customerBalance -= product.productPoints;
        product.amountExchanged += 1;

        assert(customer.customerBalance >= 0);

        emit ProductExchanged(msg.sender, _productIndex, block.timestamp);
    }

    function getContractBalance()
        public
        view
        contractOwnerOnly
        returns (uint256)
    {
        return address(this).balance;
    }

    function transferToAccount(
        address payable _destinationAddress,
        uint _amountToTransfer
    ) public contractOwnerOnly {
        uint256 amountAvailable = address(this).balance;

        require(amountAvailable >= _amountToTransfer, "Balance is not enough");

        Customer memory customer = _enrolledCustomers[_destinationAddress];

        require(isCustomerValid(customer), "Destination customer is invalid");

        amountAvailable -= _amountToTransfer;

        assert(amountAvailable >= 0);

        (bool success, ) = _destinationAddress.call{value: _amountToTransfer}(
            ""
        );

        require(success, "Could not transfer to destination address");
    }
}
