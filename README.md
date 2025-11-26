# ATM-AZURE

<img width="1631" height="941" alt="ATM drawio (2)" src="https://github.com/user-attachments/assets/8710a3fe-36d8-43ba-8066-397bc3ddd594" />

# 💳 Bank ATM Cloud Project – Azure Deployment

## 🧭 Introduction

This project simulates a cloud-based Bank ATM system deployed on Microsoft Azure. It demonstrates how to build a secure, scalable, and observable application using modern cloud architecture and DevOps practices.

The system is composed of:

- **Front-End Web App**: Hosted on Azure App Service, providing the user interface for ATM operations.
- **Back-End API**: Handles authentication, deposit/withdrawal logic, and transaction history.
- **Azure SQL Database**: Stores user accounts, balances, and transaction records.
- **Azure Key Vault**: Secures sensitive credentials and connection strings.
- **CI/CD Pipeline**: Automates deployment using GitHub Actions or Azure DevOps.
- **Monitoring Tools**: Application Insights and Log Analytics for diagnostics and performance tracking.

All resources are grouped under a single Azure Resource Group (`bank-atm-rg`) and follow best practices for naming, security, and modular deployment.

---

## 🚀 Features

- User login and authentication
- Balance inquiry
- Deposit and withdrawal operations
- Transaction history
- Secure secret management via Key Vault
- Automated deployment pipeline
- Real-time monitoring and logging

---

## 🧱 Tech Stack

| Layer        | Technology                  |
|--------------|-----------------------------|
| Front-End    | Azure App Service (.NET/Node) |
| Back-End     | Azure App Service / Azure Functions |
| Database     | Azure SQL Database          |
| Secrets      | Azure Key Vault             |
| CI/CD        | GitHub Actions / Azure DevOps |
| Monitoring   | Application Insights, Log Analytics |
| Networking   | Azure VNet, Subnets, NSG    |

---

## 📦 Resource Group

All resources are deployed under:

```bash
Resource Group: bank-atm-rg
Location: East US