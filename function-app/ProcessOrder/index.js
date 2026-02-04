/**
 * Azure Function: ProcessOrder
 * Trigger: HTTP (POST)
 * Purpose: Process e-commerce orders and trigger Logic App for email
 */

module.exports = async function (context, req) {
    const startTime = new Date();
    
    context.log('ORDER PROCESSING FUNCTION TRIGGERED');
    
    // Logic App URL - Update with your actual URL
    const LOGIC_APP_URL = process.env.LOGIC_APP_URL || 'YOUR_LOGIC_APP_URL_HERE';
    
    // CORS Headers
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    };
    
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        context.res = { status: 204, headers };
        return;
    }
    
    // Handle GET - API info
    if (req.method === 'GET') {
        context.res = {
            status: 200,
            headers,
            body: {
                message: 'Order Processing API',
                version: '2.0.0',
                status: 'Running',
                timestamp: new Date().toISOString()
            }
        };
        return;
    }
    
    // Handle POST - Process Order
    try {
        const order = req.body;
        
        if (!order || Object.keys(order).length === 0) {
            context.res = {
                status: 400,
                headers,
                body: { success: false, message: 'Request body is empty' }
            };
            return;
        }
        
        // Generate Order ID
        if (!order.orderId) {
            order.orderId = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;
        }
        order.orderDate = order.orderDate || new Date().toISOString();
        
        // Validate order
        const validation = validateOrder(order);
        if (!validation.isValid) {
            context.res = {
                status: 400,
                headers,
                body: { success: false, errors: validation.errors }
            };
            return;
        }
        
        // Calculate totals
        const summary = calculateTotals(order);
        
        // Call Logic App for email
        let emailResult = { sent: false, message: 'Not configured' };
        if (LOGIC_APP_URL && LOGIC_APP_URL !== 'YOUR_LOGIC_APP_URL_HERE') {
            try {
                const payload = {
                    orderId: order.orderId,
                    customerName: order.customerName,
                    customerEmail: order.customerEmail,
                    items: order.items,
                    summary: summary,
                    orderDate: order.orderDate
                };
                
                const response = await fetch(LOGIC_APP_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                
                emailResult = response.ok 
                    ? { sent: true, message: 'Email sent via Logic App' }
                    : { sent: false, message: `Logic App error: ${response.status}` };
            } catch (e) {
                emailResult = { sent: false, message: e.message };
            }
        }
        
        const processingTime = new Date() - startTime;
        
        context.res = {
            status: 200,
            headers,
            body: {
                success: true,
                message: 'Order processed successfully!',
                order: {
                    orderId: order.orderId,
                    status: 'Confirmed',
                    summary: summary,
                    orderDate: order.orderDate
                },
                emailNotification: emailResult,
                processingTimeMs: processingTime
            }
        };
        
    } catch (error) {
        context.log.error('Order processing error:', error);
        context.res = {
            status: 500,
            headers,
            body: { success: false, error: error.message }
        };
    }
};

function validateOrder(order) {
    const errors = [];
    if (!order.customerName) errors.push('Customer name required');
    if (!order.customerEmail) errors.push('Customer email required');
    if (!order.items || order.items.length === 0) errors.push('Order must have items');
    return { isValid: errors.length === 0, errors };
}

function calculateTotals(order) {
    const subtotal = order.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const tax = Math.round(subtotal * 0.18);
    const shipping = subtotal >= 500 ? 0 : 50;
    const discount = subtotal >= 50000 ? Math.round(subtotal * 0.10) : 0;
    const total = subtotal + tax + shipping - discount;
    const itemCount = order.items.reduce((sum, item) => sum + item.quantity, 0);
    return { subtotal, tax, shipping, discount, total, itemCount };
}
