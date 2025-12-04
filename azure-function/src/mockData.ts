// Mock data for users and products

export interface User {
    id: string;
    name: string;
    email: string;
    role: string;
}

export interface Product {
    id: string;
    name: string;
    description: string;
    price: number;
    category: string;
}

export const mockUsers: User[] = [
    {
        id: "1",
        name: "John Doe",
        email: "john.doe@example.com",
        role: "admin"
    },
    {
        id: "2",
        name: "Jane Smith",
        email: "jane.smith@example.com",
        role: "user"
    },
    {
        id: "3",
        name: "Bob Wilson",
        email: "bob.wilson@example.com",
        role: "user"
    },
    {
        id: "4",
        name: "Alice Brown",
        email: "alice.brown@example.com",
        role: "moderator"
    },
    {
        id: "5",
        name: "Charlie Davis",
        email: "charlie.davis@example.com",
        role: "user"
    }
];

export const mockProducts: Product[] = [
    {
        id: "1",
        name: "Laptop Pro",
        description: "High-performance laptop for professionals",
        price: 1299.99,
        category: "Electronics"
    },
    {
        id: "2",
        name: "Wireless Mouse",
        description: "Ergonomic wireless mouse with precision tracking",
        price: 49.99,
        category: "Accessories"
    },
    {
        id: "3",
        name: "Mechanical Keyboard",
        description: "RGB mechanical keyboard with Cherry MX switches",
        price: 149.99,
        category: "Accessories"
    },
    {
        id: "4",
        name: "4K Monitor",
        description: "27-inch 4K UHD monitor with HDR support",
        price: 599.99,
        category: "Electronics"
    },
    {
        id: "5",
        name: "USB-C Hub",
        description: "Multi-port USB-C hub with HDMI and Ethernet",
        price: 79.99,
        category: "Accessories"
    },
    {
        id: "6",
        name: "Noise-Cancelling Headphones",
        description: "Premium wireless headphones with ANC",
        price: 349.99,
        category: "Audio"
    },
    {
        id: "7",
        name: "Webcam HD",
        description: "1080p HD webcam with built-in microphone",
        price: 89.99,
        category: "Electronics"
    },
    {
        id: "8",
        name: "Standing Desk",
        description: "Electric height-adjustable standing desk",
        price: 699.99,
        category: "Furniture"
    }
];
