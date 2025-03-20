# Secure Azure ML Integration with Local PostgreSQL: A Step-by-Step Guide

1. A secure Azure ML workspace (with private endpoints and virtual networks).  
2. A VPN or ExpressRoute (or other secure channel) connecting  On-premises(local Server PostgreSQL) PostgreSQL database to Azure ML.  
3. A functioning pipeline/notebook (in Azure ML) that accesses  local PostgreSQL data, trains the model, and stores it in Azure ML.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)  
2. [Architecture Overview](#2-architecture-overview)  
    - [Components and their purposes](#components-and-their-purposes)  
3. [Step 1: Create an Azure Resource Group](#3-step-1-create-an-azure-resource-group)  
4. [Step 2: Create a Virtual Network](#4-step-2-create-a-virtual-network)  
5. [Step 3: Set Up On-premises(local Server PostgreSQL)-to-Azure Connection](#5-step-3-set-up-on-premiseslocal-server-postgresql-to-azure-connection)  
    - [3.1. Using a Point-to-Site VPN](#31-using-a-point-to-site-vpn)  
    - [3.2. Using Azure ExpressRoute](#32-using-azure-expressroute)  
6. [Step 4: Create a Secure Azure Machine Learning Workspace](#6-step-4-create-a-secure-azure-machine-learning-workspace)  
    - [4.1. Create the Azure ML Workspace](#41-create-the-azure-ml-workspace)  
    - [4.2. Enable Private Endpoints](#42-enable-private-endpoints-private-link)  
    - [4.3. Configure Azure Key Vault for Secrets](#43-configure-azure-key-vault-for-secrets)  
7. [Step 5: Configure Network Security](#7-step-5-configure-network-security)  
    - [5.1. Network Security Groups](#51-network-security-groups-nsgs)  
    - [5.2. Firewall Considerations for PostgreSQL](#52-firewall-considerations-for-postgresql)  
8. [Step 6: Connect Azure ML to PostgreSQL](#8-step-6-connect-azure-ml-to-postgresql)  
    - [6.1. Install PostgreSQL Drivers](#61-install-postgresql-drivers-on--compute-environment)  
    - [6.2. Securely Store Credentials](#62-securely-store-credentials-in-azure-key-vault)  
    - [6.3. Accessing PostgreSQL from Azure ML](#63-accessing-postgresql-from-azure-ml-code-example)  
9. [Step 7: Train Model in Azure ML](#9-step-7-train--model-in-azure-ml)  
    - [7.1. Create an Azure ML Compute Cluster](#71-create-an-azure-ml-compute-cluster)  
    - [7.2. Submit a Training Job or Run a Notebook](#72-submit-a-training-job-or-run-a-notebook)  
    - [7.3. Store and Version Model](#73-store-and-version--model-in-azure-ml)  
10. [Step 8: Validate the End-to-End Workflow](#10-step-8-validate-the-end-to-end-workflow)  
11. [Additional Best Practices & Troubleshooting Tips](#11-additional-best-practices--troubleshooting-tips)  


---

## 1. Prerequisites

- **Azure Subscription**: We need an active Azure subscription with rights to create resource groups, VNets, and Azure Machine Learning resources.  
- **Local (On-premises(local Server PostgreSQL)) PostgreSQL Database**: We have a running PostgreSQL instance within  local network. Ensure that you have permissions to create new database users or configure network settings.  
- **Networking Equipment/Capability**: If you want to establish a secure hybrid connection (VPN or ExpressRoute), ensure  local infrastructure can support it.  
- **Azure CLI / Azure Portal Access**: Make sure the Azure CLI is installed locally (optional if you prefer Azure Portal). Both tools enable you to manage Azure resources:
    - Azure CLI offers scriptable, command-line automation
    - Azure Portal provides a user-friendly visual interface
    - Choose based on our preference for GUI vs command-line work

---

## 2. architecture overview

### Components and their purposes

#### 1️⃣ virtual network (azure)
- creates an isolated network environment
- houses all azure resources securely
- controls communication paths

#### 2️⃣ azure machine learning workspace
- Configured with Private Endpoints
- Secures access to:
    - ML workspace resources
    - Storage accounts
    - Associated services
- No public internet exposure

#### 3️⃣ Connectivity Solution
- Options:
    - Point-to-Site VPN
    - or: 
        - Site-to-Site VPN
        - Azure ExpressRoute
- Securely connects:
    - On-premises(local Server PostgreSQL) network (PostgreSQL)
    - Azure Virtual Network

#### 4️⃣ Network Security Groups (NSGs)
- Controls network traffic flow
- Manages:
    - Inbound rules
    - Outbound rules
- Adds security layer

#### 5️⃣ Azure Key Vault
- Securely stores:
    - PostgreSQL credentials
    - Connection strings
    - Other secrets
- Integrates with Azure ML



Below is a simplified diagram (in text):

```
On-premises(local Server PostgreSQL) Network (Local PostgreSQL)
    | 
    |--- (VPN or ExpressRoute) ---|
    |
 Azure Virtual Network -------- NSG ----------
    |                                   
    |---- Private Endpoint for AML Workspace  
    |---- Azure Machine Learning Workspace    
    |---- Azure Key Vault (stores secrets)    
    |---- AML Compute Cluster (training runs)
```

[View the full architecture diagram here](architectureworkflow.puml)


---

## 3. Step 1: Create an Azure Resource Group

<details>
<summary><b>🔍 Learn how to create a Resource Group</b></summary>

An Azure Resource Group (RG) is a logical container that holds related Azure resources. You can create an RG in the Azure Portal or via CLI.

**Using Azure CLI**:

```bash
# Variables
LOCATION="eastus"
RESOURCE_GROUP="my-aml-rg"

# Create Resource Group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

</details>


## 4. Step 2: Create a Virtual Network

<details>
<summary><b>🔗 Learn how to create and configure a Virtual Network</b></summary>

Create a virtual network that  out Azure ML workspace and our compute resources will use. It will also house the private endpoints.

Before proceeding, review the [Azure Virtual Networks guide](https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-virtual-networks?utm_source=chatgpt.com&tabs=portal) for detailed network setup instructions.

<details>
<summary><b>🔄 Example using Azure CLI</b></summary>

1. **Address Space**: Define an address space that does not overlap with  On-premises(local Server PostgreSQL) network.  
2. **Subnets**: Typically, you will have separate subnets for  compute resources,  private endpoints, etc.

**Using Azure CLI**:

```bash
VNET_NAME="my-aml-vnet"
SUBNET_NAME="my-aml-subnet"
ADDRESS_PREFIX="10.0.0.0/16"  # Adjust as needed
SUBNET_PREFIX="10.0.0.0/24"   # Adjust as needed

# Create VNet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefixes $ADDRESS_PREFIX \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix $SUBNET_PREFIX
```
</details>
</details>


## 5. Step 3: Set Up On-premises(local Server PostgreSQL)-to-Azure Connection

<details>
<summary><b>🌐 Configure Secure Connection Between On-premises PostgreSQL and Azure</b></summary>

To allow Azure resources to communicate with  local PostgreSQL database, you need a secure connection between  on-premise network and Azure. Typically, you can use either:
<details>
<summary><b>🔄 Click to Learn About Connectivity Options</b></summary>

### Point-to-Site VPN (P2S)
- One computer connects to Azure at a time
- Best for developers and testing
- Simple setup, no network changes needed
- Like a direct call to customer support

### Site-to-Site VPN (S2S)
- Connects entire On-premises(local Server PostgreSQL) network to Azure
- Best for multiple computers/servers
- Requires local VPN device configuration
- Like connecting two offices with a virtual highway

### Azure ExpressRoute
- Private, dedicated connection
- Best for large organizations
- Highest speed and security
- Like a private bridge between  office and Azure

#### Comparison Table
| Feature | Point to Site VPN | Site to Site VPN | ExpressRoute |
|---------|---------|---------|--------------|
| **Who connects?** | Single PC at time | Full Network | Full Network via a private link |
| **Internet Use** | Yes | Yes | No |
| **Speed** | Basic | Moderate | High |
| **Cost** | Low | Moderate | High |
| **Setup** | Simple | Moderate | Complex |

</details>

### 3.1 Using a Point-to-Site VPN

1. **Create a Virtual Network Gateway** in Azure:
  - Select "VPN" as the gateway type
  - Configure with appropriate SKU (Basic for testing, VpnGw1 or higher for production)
  - Link it to  Azure virtual network

2. **Configure P2S Settings**:
  - Generate root and client certificates
  - Upload root certificate to the gateway
  - Define the client address pool (e.g., 172.16.0.0/24)

3. **Set Up Client Connection**:
  - Download and install the VPN client configuration from Azure portal
  - Install the client certificate on  machine
  - Connect using the Azure VPN Client

4. **Verify** that you can pass traffic between on-prem and Azure (e.g., ping tests).

> [Azure documentation on Point-to-Site VPN](https://learn.microsoft.com/azure/vpn-gateway/point-to-site-about) provides detailed setup steps.

### 3.2 Using Azure ExpressRoute

If you require more reliable or higher bandwidth, you can use **ExpressRoute**. You would:

1. **Provision an ExpressRoute Circuit** through an ExpressRoute provider.  
2. **Link** the circuit to  Azure Virtual Network.  
3. **Configure** routing in  On-premises(local Server PostgreSQL) network to allow connectivity.

> [ExpressRoute documentation](https://learn.microsoft.com/azure/expressroute/) can guide you further.

</details>

---

## 6. Step 4: Create a Secure Azure Machine Learning Workspace

<details>
<summary><b>🔒 Learn how to create and secure your Azure ML Workspace</b></summary>

### 4.1 Create the Azure ML Workspace

You can create a workspace either via the Portal or CLI.

**Using Azure CLI**:

```bash
WORKSPACE_NAME="my-secure-aml-workspace"

az ml workspace create \
  --name $WORKSPACE_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

### 4.2 Enable Private Endpoints (Private Link)

After creating the workspace, you can enable **private endpoints** for key Azure ML components such as the **workspace, storage account, and container registry** that AML uses. This ensures traffic flows only over  private VNet connection and not the public internet.

1. **Identify** or create the subnets dedicated to private endpoints.  
2. **Configure** each resource (workspace, storage, Key Vault, etc.) to use a private endpoint.  

**In the Portal**, you would:  
- Go to  AML workspace \> Networking \> Private endpoint connections \> + Private endpoint.  
- Choose the relevant resource (e.g., AML workspace, storage, etc.).  
- Link to the VNet and private endpoint subnet.

> [Azure ML documentation on Private Link](https://learn.microsoft.com/azure/machine-learning/how-to-create-workspace-private-link) has step-by-step instructions.

### 4.3 Configure Azure Key Vault for Secrets

Azure ML automatically creates or associates a Key Vault. You can store secrets (e.g., PostgreSQL credentials) here. Make sure Key Vault also uses **private endpoints** if you want to keep everything in  private network.  

---

</details>


## 7. Step 5: Configure Network Security

<details>
<summary><b>🛡️ Learn how to configure network security rules and firewalls</b></summary>

### 5.1 Network Security Groups (NSGs)

Network Security Groups (NSGs) let you permit or deny inbound/outbound traffic at the subnet or NIC level.

1. **Create an NSG** for  AML subnet(s):  

  ```bash
  NSG_NAME="my-aml-nsg"

  az network nsg create \
    --resource-group $RESOURCE_GROUP \
    --name $NSG_NAME \
    --location $LOCATION
  ```

2. **Associate** it with  AML subnet:  

  ```bash
  az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --network-security-group $NSG_NAME
  ```

3. **Add Inbound/Outbound Rules** to allow traffic to  on-prem network (PostgreSQL default port is **5432**).  

  ```bash
  # Example: Allow outbound to PostgreSQL server on 5432
  az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name "Allow-PostgreSQL-Outbound" \
    --priority 1000 \
    --direction Outbound \
    --access Allow \
    --protocol Tcp \
    --destination-port-ranges 5432 \
    --destination-address-prefixes <on-prem-subnet-address-range>
  ```

> Be sure to restrict inbound traffic to only necessary ports (e.g., from  local IP for debugging or from the AML compute if needed).

### 5.2 Firewall Considerations for PostgreSQL

On  **local PostgreSQL** side:
- Ensure  firewall rules allow inbound connections from the Azure VNet address space (e.g., `10.0.0.0/16` in this example).  
- Update `postgresql.conf` and `pg_hba.conf` if needed to allow connections from the Azure address range.

---

</details>


## 8. Step 6: Connect Azure ML to PostgreSQL

<details>
<summary><b>🔌 Learn how to connect Azure ML to your PostgreSQL database</b></summary>

### 6.1 Install PostgreSQL Drivers on  Compute Environment

 AML compute environment needs the PostgreSQL Python driver (`psycopg2` or `pg8000`) installed.

If using an Azure ML **conda environment** or a custom Docker image, include:

```yaml
# environment.yml example
name: my-aml-env
dependencies:
  - python=3.9
  - pip:
    - psycopg2
    - azureml-core
    - azureml-defaults
```

When you deploy a training script, specify this environment.

### 6.2 Securely Store Credentials in Azure Key Vault

Rather than hard-coding credentials, store them in Key Vault. For instance:

1. **Set a secret** in  AML-Linked Key Vault:  

   ```bash
   # Example of storing PostgreSQL password
   KEY_VAULT_NAME="<-kv-name>"
   PG_PASSWORD="MySuperSecret"

   az keyvault secret set \
     --vault-name $KEY_VAULT_NAME \
     --name "PostgresPassword" \
     --value "$PG_PASSWORD"
   ```

2. You can store the username, hostname, etc. as separate secrets or store them in a single JSON.  

### 6.3 Accessing PostgreSQL from Azure ML (Code Example)

Below is a simplified Python snippet that shows how you might access secrets from Key Vault and connect to PostgreSQL.

```python
import os
import psycopg2
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

# 1. Connect to Key Vault
key_vault_uri = f"https://{KEY_VAULT_NAME}.vault.azure.net"
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)

# 2. Retrieve secrets
postgres_user = secret_client.get_secret("PostgresUser").value
postgres_pass = secret_client.get_secret("PostgresPassword").value
postgres_host = secret_client.get_secret("PostgresHost").value
postgres_db   = secret_client.get_secret("PostgresDatabase").value

# 3. Connect to local PostgreSQL (through VPN/ExpressRoute)
conn = psycopg2.connect(
    dbname=postgres_db,
    user=postgres_user,
    password=postgres_pass,
    host=postgres_host,
    port=5432
)

cursor = conn.cursor()
cursor.execute("SELECT version();")
record = cursor.fetchone()
print(f"Connected to PostgreSQL version: {record}")

# 4. (Optional) Query data
cursor.execute("SELECT * FROM my_table LIMIT 10;")
results = cursor.fetchall()
print(results)

cursor.close()
conn.close()
```

> Ensure that the Azure ML compute can reach the Key Vault over the private endpoint (no public internet) and that  Key Vault firewall is configured properly (allowing only trusted Azure services or the specific VNet traffic).

</details>

---

## 9. Step 7: Train Model in Azure ML

  <details>
  <summary><b>🔬 Learn how to train and register your model in Azure ML</b></summary>

  ### 7.1 Create an Azure ML Compute Cluster

  Use the Azure Portal or CLI to create a compute cluster that is attached to  secure workspace and VNet.

  **Using Azure CLI**:

  ```bash
  COMPUTE_NAME="my-aml-compute"
  az ml compute create \
    --name $COMPUTE_NAME \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $WORKSPACE_NAME \
    --type amlcompute \
    --size Standard_DS3_v2 \
    --min-instances 0 \
    --max-instances 2
  ```

  ### 7.2 Submit a Training Job or Run a Notebook

  In Azure ML, you can run:

  1. **Notebooks**: Launch a notebook instance in the AML Studio environment, using  custom environment with `psycopg2`.  
  2. **Training Script via a ScriptRunConfig**:  

  ```python
  from azureml.core import Workspace, Experiment, ScriptRunConfig, Environment
  from azureml.core.runconfig import RunConfiguration

  ws = Workspace.get(name=WORKSPACE_NAME, resource_group=RESOURCE_GROUP)
  experiment = Experiment(workspace=ws, name="my-postgres-experiment")

  # Define environment
  env = Environment.from_conda_specification(name="my-env", file_path="environment.yml")

  # Define run config
  run_config = RunConfiguration()
  run_config.environment = env

  src = ScriptRunConfig(
      source_directory=".",
      script="train_script.py",
      run_config=run_config,
      compute_target=COMPUTE_NAME
  )

  run = experiment.submit(src)
  run.wait_for_completion(show_output=True)
  ```

  ### 7.3 Store and Version  Model in Azure ML

  After training, register the trained model in Azure ML's model registry:

  ```python
  from azureml.core.model import Model

  model = Model.register(workspace=ws,
                        model_path="outputs/my_model.pkl",  # Path in the run output
                        model_name="my_trained_model",
                        tags={"source": "postgres_data"})
  print(f"Model registered: {model.name}, version: {model.version}")
  ```

  </details>

  ---


  ## 10. Step 8: Validate the End-to-End Workflow
  <details>
  <summary><b>🔍 Learn how to validate your end-to-end workflow</b></summary>

## 10. Step 8: Validate the End-to-End Workflow

1. **From AML Notebook** (or a training script), ensure you can run a simple query on  local PostgreSQL.  
2. **Ensure** no error regarding connectivity or credential access.  
3. **Check**  on-prem logs to see if the traffic is indeed coming from the private IP range of  Azure VNet.  
4. **Confirm** the AML run completes successfully and the model artifact is stored in the AML workspace.  

</details>

---

# Summary

In this tutorial, We created a **secure environment** in Azure for Machine Learning by:

1. **Setting up a Resource Group and Virtual Network**  
2. **Establishing a secure connection (VPN/ExpressRoute)** to On-premises(local Server PostgreSQL)  
3. **Creating and configuring a private Azure ML workspace** with private endpoints and Key Vault  
4. **Allowing AML compute to connect to the on-prem PostgreSQL** server securely (via private networking)  
5. **Training and registering a model** within Azure ML

By following these steps, you ensure that no data is exposed to the public internet and that  ML training pipeline is fully compliant with security best practices. This approach is especially useful for organizations dealing with sensitive or regulated data that must remain On-premises(local Server PostgreSQL).

---

**References for Further Reading**:

- **Create and manage a secure workspace in Azure Machine Learning**  
  [Microsoft Docs](https://learn.microsoft.com/azure/machine-learning/how-to-secure-workspace-vnet)  

- **Virtual Network Over view**  
    [Microsoft Docs](https://learn.microsoft.com/azure/vpn-gateway/tutorial-site-to-site-portal)  


- **Azure ExpressRoute**  
  [Microsoft Docs](https://learn.microsoft.com/azure/expressroute/)  

- **Azure Key Vault**  
  [Microsoft Docs](https://learn.microsoft.com/azure/key-vault/)  

- **Azure Machine Learning Environments**  
  [Microsoft Docs](https://learn.microsoft.com/azure/machine-learning/concept-environments)  