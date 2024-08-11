Invoices:
    invoice_id (Primary Key)
    customer_id (Foreign Key)
    invoice_number
    issue_date
    due_date
    total_amount
    payment_status

Invoice Items:
    item_id (Primary Key)
    invoice_id (Foreign Key)
    product_id (Foreign Key)
    license_id (Foreign Key)
    quantity
    unit_price
    subtotal_amount

Payments:
    payment_id (Primary Key)
    invoice_id (Foreign Key)
    payment_date
    payment_amount
    payment_method
    transaction_id (if applicable)

Payment Methods:
    method_id (Primary Key)
    method_name
    description

Currency:
    currency_id (Primary Key)
    currency_code
    currency_name
    exchange_rate

Tax:
    tax_id (Primary Key)
    tax_name
    tax_rate

Discounts:
    discount_id (Primary Key)
    discount_code
    discount_description
    discount_rate (if applicable)