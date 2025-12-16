# Azure Web App with Entra ID Authentication

A complete Azure solution featuring a web application with Entra ID (Azure AD) authentication, Azure Functions for the API layer, API Management for API governance, and Azure Container Apps for container-based deployment. Infrastructure is defined using Bicep.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                              │
│                                                                  │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐  │
│  │   Entra ID  │    │  API Management │    │ Container Apps  │  │
│  │   (Auth)    │◄───┤    Gateway      │◄───┤   Environment   │  │
│  └─────────────┘    └────────┬────────┘    └────────┬────────┘  │
│                              │                       │           │
│                              │         ┌─────────────┴──────┐   │
│                              │         │                    │   │
│                              │    ┌────▼────┐    ┌─────────▼┐   │
│                              │    │ Web App │    │  Azure   │   │
│                              │    │Container│    │ Function │   │
│                              │    │   App   │    │   App    │   │
│                              │    └─────────┘    └──────────┘   │
│                              │                                   │
│  ┌─────────────────┐    ┌────▼────────────┐                     │
│  │  Log Analytics  │◄───┤ App Insights    │                     │
│  └─────────────────┘    └─────────────────┘                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Container Registry                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

## Features

- **Entra ID Authentication**: Secure user authentication using Microsoft Entra ID (Azure AD)
- **Azure Functions**: Serverless API with mocked data (users and products)
- **API Management**: Centralized API gateway with JWT validation
- **Container Apps**: Container-based deployment with auto-scaling
- **Infrastructure as Code**: Bicep templates for reproducible deployments
- **Monitoring**: Application Insights and Log Analytics integration

## Project Structure

```
azure-web-app/
├── infra/                          # Infrastructure as Code (Bicep)
│   ├── main.bicep                  # Main deployment template
│   ├── parameters.json             # Deployment parameters
│   └── modules/                    # Bicep modules
│       ├── api-management.bicep    # API Management service
│       ├── app-insights.bicep      # Application Insights
│       ├── container-app.bicep     # Web App Container App
│       ├── container-apps-environment.bicep  # Container Apps Environment
│       ├── container-registry.bicep # Azure Container Registry
│       ├── function-app.bicep      # Azure Function Container App
│       └── log-analytics.bicep     # Log Analytics Workspace
├── webapp/                         # Web Application
│   ├── src/
│   │   ├── server.ts               # Express server
│   │   ├── auth.ts                 # MSAL authentication
│   │   └── config.ts               # Configuration
│   ├── public/
│   │   └── index.html              # Frontend UI
│   ├── Dockerfile                  # Docker image definition
│   ├── package.json                # Node.js dependencies
│   └── tsconfig.json               # TypeScript configuration
├── azure-function/                 # Azure Functions
│   ├── src/
│   │   ├── mockData.ts             # Mock data (users, products)
│   │   └── functions/
│   │       ├── getUsers.ts         # Get users API
│   │       ├── getProducts.ts      # Get products API
│   │       └── healthCheck.ts      # Health check endpoint
│   ├── Dockerfile                  # Docker image definition
│   ├── host.json                   # Functions host configuration
│   ├── package.json                # Node.js dependencies
│   └── tsconfig.json               # TypeScript configuration
└── README.md                       # This file
```

## Prerequisites

- Azure CLI
- Azure subscription
- Entra ID tenant with permissions to create app registrations
- Docker (for local development and building images)
- Node.js 20+

## Setup

### 1. Create Entra ID App Registrations

You need to create two app registrations in Entra ID:

#### Web App Registration
1. Go to Azure Portal > Entra ID > App registrations
2. Click "New registration"
3. Name: "Azure Web App"
4. Supported account types: "Accounts in this organizational directory only"
5. Redirect URI: Web - `https://<your-container-app-url>/auth/callback`
6. After creation, note the **Application (client) ID** and **Directory (tenant) ID**
7. Under "Certificates & secrets", create a new client secret

#### API Registration
1. Create another app registration for the API
2. Name: "Azure Web App API"
3. Under "Expose an API", add a scope: `api://<api-client-id>/.default`
4. Note the **Application (client) ID**

### 2. Configure Parameters

Edit `infra/parameters.json` with your values:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "dev"
    },
    "tenantId": {
      "value": "your-tenant-id"
    },
    "webAppClientId": {
      "value": "your-web-app-client-id"
    },
    "apiClientId": {
      "value": "your-api-client-id"
    }
  }
}
```

### 3. Deploy Infrastructure

```bash
# Login to Azure
az login

# Create a resource group
az group create --name rg-azure-webapp --location eastus

# Deploy infrastructure using Bicep
az deployment group create \
  --resource-group rg-azure-webapp \
  --template-file infra/main.bicep \
  --parameters infra/parameters.json
```

### 4. Build and Push Docker Images

```bash
# Get ACR login server from deployment outputs
ACR_NAME=$(az deployment group show \
  --resource-group rg-azure-webapp \
  --name main \
  --query properties.outputs.containerRegistryLoginServer.value -o tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push web app
cd webapp
docker build -t $ACR_NAME/webapp:latest .
docker push $ACR_NAME/webapp:latest

# Build and push function app
cd ../azure-function
docker build -t $ACR_NAME/function:latest .
docker push $ACR_NAME/function:latest
```

### 5. Update Container Apps with New Images

```bash
# Update web app container
az containerapp update \
  --name <web-app-name> \
  --resource-group rg-azure-webapp \
  --image $ACR_NAME/webapp:latest

# Update function app container
az containerapp update \
  --name <function-app-name> \
  --resource-group rg-azure-webapp \
  --image $ACR_NAME/function:latest
```

## Local Development

### Web App

```bash
cd webapp
npm install
npm run dev

# Open http://localhost:3000
```

### Azure Function

```bash
cd azure-function
npm install
npm run build
npm start

# Functions available at http://localhost:7071/api/
```

## API Endpoints

### Azure Function Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/users` | GET | Get all mock users |
| `/api/users?role=admin` | GET | Get users by role |
| `/api/products` | GET | Get all mock products |
| `/api/products?category=Electronics` | GET | Get products by category |
| `/api/health` | GET | Health check endpoint |

### Web App Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Protected home page (requires auth) |
| `/login` | GET | Initiate Entra ID login |
| `/logout` | GET | Logout and redirect |
| `/auth/callback` | GET | OAuth callback handler |
| `/api/me` | GET | Get current user info |
| `/api/users` | GET | Proxy to function app |
| `/api/products` | GET | Proxy to function app |

## Security

- **JWT Validation**: API Management validates JWT tokens from Entra ID
- **HTTPS Only**: All traffic is encrypted
- **PKCE Flow**: Web app uses PKCE for secure OAuth flow
- **Session Management**: Secure session handling with HTTP-only cookies
- **Container Isolation**: Each service runs in isolated containers

## Monitoring

- **Application Insights**: Tracks requests, dependencies, and exceptions
- **Log Analytics**: Centralized logging for all components
- **Container App Metrics**: Auto-scaling based on HTTP traffic

## Cost Optimization

- **Consumption Tier**: API Management uses consumption tier
- **Auto-scaling**: Container Apps scale to zero when idle
- **Basic Registry**: Container Registry uses Basic SKU

## License

MIT