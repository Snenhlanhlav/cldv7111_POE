# EventEase — Venue Booking System

A full-stack **ASP.NET Core 8 MVC** web application for managing venue bookings, events, and
scheduling — built for EventEase across three development phases.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Database Design](#database-design)
4. [Features by Phase](#features-by-phase)
5. [Local Development Setup](#local-development-setup)
6. [Azure Deployment Guide](#azure-deployment-guide)
7. [Part D — Theory Questions](#part-d--theory-questions)

---

## Architecture Overview

```
Browser ──► Azure App Service (ASP.NET Core MVC)
                │
                ├──► Azure SQL Database
                │         Tables: Venues, Events, Bookings, EventTypes
                │         View:   vw_BookingDetails
                │
                └──► Azure Blob Storage
                          Containers: venue-images, event-images
```

---

## Project Structure

```
EventEase/
├── Controllers/
│   ├── HomeController.cs        # Dashboard + stats
│   ├── VenuesController.cs      # CRUD + image upload
│   ├── EventsController.cs      # CRUD + image upload + filters
│   └── BookingsController.cs    # CRUD + double-booking guard + filters
├── Data/
│   └── ApplicationDbContext.cs  # EF Core context + model config
├── Migrations/
│   └── 20240101000000_InitialCreate.cs
├── Models/
│   ├── Venue.cs
│   ├── Event.cs
│   ├── Booking.cs
│   ├── EventType.cs
│   └── BookingDetail.cs         # Keyless entity → vw_BookingDetails
├── Services/
│   └── BlobStorageService.cs    # Azure Blob upload/delete
├── Views/
│   ├── Home/Index.cshtml        # Dashboard
│   ├── Venues/                  # Index, Create, Edit, Details, Delete
│   ├── Events/                  # Index, Create, Edit, Details, Delete
│   ├── Bookings/                # Index, Create, Edit, Details, Delete
│   └── Shared/_Layout.cshtml
├── wwwroot/css/site.css
├── EventEase_Database.sql       # Full SQL script
├── Program.cs
└── appsettings.json
```

---

## Database Design

### ERD (Entity Relationship Diagram)

```
┌──────────────┐        ┌──────────────────┐        ┌──────────────┐
│  EventTypes  │        │     Events       │        │    Venues    │
│──────────────│        │──────────────────│        │──────────────│
│ EventTypeId PK│◄──────│ EventTypeId  FK  │        │ VenueId    PK│
│ TypeName     │  0..N  │ EventId      PK  │  N..1  │ VenueName    │
└──────────────┘        │ EventName        │────────│ Location     │
                        │ EventDate        │        │ Capacity     │
                        │ EndDate          │        │ ImageUrl     │
                        │ Description      │        │ IsAvailable  │
                        │ ImageUrl         │        └──────┬───────┘
                        │ VenueId      FK  │               │
                        └────────┬─────────┘               │
                                 │ 1                        │ 1
                                 │                          │
                        ┌────────┴─────────┐               │
                        │     Bookings     │               │
                        │──────────────────│               │
                        │ BookingId    PK  │               │
                        │ EventId      FK  │               │
                        │ VenueId      FK  │───────────────┘
                        │ BookingDate      │
                        └──────────────────┘

                        ┌────────────────────────────────────────────┐
                        │         vw_BookingDetails (VIEW)           │
                        │  BookingId, BookingDate, EventName,        │
                        │  EventDate, EndDate, EventDescription,     │
                        │  EventTypeName, VenueName, Location,       │
                        │  Capacity, VenueImageUrl, EventImageUrl    │
                        └────────────────────────────────────────────┘
```

### Tables

| Table | Key Columns | Purpose |
|---|---|---|
| `Venues` | VenueId (PK) | Stores venue details + availability flag |
| `Events` | EventId (PK), VenueId (FK, nullable) | Events; venue optional at creation |
| `Bookings` | BookingId (PK), EventId (FK), VenueId (FK) | Associative — links event to venue |
| `EventTypes` | EventTypeId (PK) | Lookup table for event categories |
| `vw_BookingDetails` | — (VIEW) | Consolidated booking display |

---

## Features by Phase

### Part 1 — Foundation
- ✅ Models: Venue, Event, Booking (+ EventType for Part 3)
- ✅ Full CRUD for Venues, Events, Bookings
- ✅ Dashboard with stats and upcoming events
- ✅ Placeholder URL support for images
- ✅ Azure SQL Database integration via EF Core
- ✅ Azure App Service deployment

### Part 2 — Enhancements
- ✅ **Azure Blob Storage** for venue and event images (upload or URL)
- ✅ **Double-booking prevention** — same venue, same date blocked
- ✅ **Delete restrictions** — venues/events with bookings cannot be deleted
- ✅ **Alert system** — TempData alerts for success/error
- ✅ **vw_BookingDetails** — consolidated view via SQL VIEW + EF keyless entity
- ✅ **Search** — by Booking ID, Event Name, Venue Name in bookings view
- ✅ Client-side and server-side validation

### Part 3 — Advanced Filtering
- ✅ **EventType** lookup table with 10 predefined categories
- ✅ **IsAvailable** flag on Venue
- ✅ **Advanced filters** — event type, date range, venue on all list views
- ✅ Fully deployed to Azure with all integrations

---

## Local Development Setup

### Prerequisites
- .NET 8 SDK
- SQL Server LocalDB (included with Visual Studio)
- Visual Studio 2022

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/EventEase.git
   cd EventEase
   ```

2. **Configure `appsettings.json`**
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=EventEaseDb;Trusted_Connection=True;"
     },
     "AzureStorage": {
       "ConnectionString": "UseDevelopmentStorage=true"
     }
   }
   ```
   > For local image development, use [Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite) as a local storage emulator.

3. **Apply migrations**
   ```bash
   dotnet ef database update
   ```
   Or use Visual Studio Package Manager Console:
   ```
   Update-Database
   ```

4. **Run**
   ```bash
   dotnet run
   ```
   Navigate to `https://localhost:7xxx`

---

## Azure Deployment Guide

### Step 1 — Create Azure Resources

```bash
# Variables
RESOURCE_GROUP="rg-eventease"
LOCATION="southafricanorth"
SQL_SERVER="sql-eventease-$(date +%s)"
SQL_DB="EventEaseDb"
STORAGE_ACCOUNT="storeventease$(date +%s)"
APP_SERVICE_PLAN="plan-eventease"
WEB_APP="app-eventease-$(date +%s)"

# Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Azure SQL Server + Database
az sql server create \
  --name $SQL_SERVER \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user sqladmin \
  --admin-password "EventEase@2025!"

az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

az sql db create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name $SQL_DB \
  --service-objective S0

# Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# App Service Plan + Web App
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku B1 \
  --is-linux false

az webapp create \
  --name $WEB_APP \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|8.0"
```

### Step 2 — Configure App Settings

```bash
# Get connection strings
SQL_CONN=$(az sql db show-connection-string \
  --server $SQL_SERVER --name $SQL_DB --client ado.net \
  --output tsv | sed "s/<username>/sqladmin/;s/<password>/EventEase@2025!/")

STORAGE_CONN=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --output tsv)

# Set App Service configuration
az webapp config appsettings set \
  --name $WEB_APP \
  --resource-group $RESOURCE_GROUP \
  --settings \
    "ConnectionStrings__DefaultConnection=$SQL_CONN" \
    "AzureStorage__ConnectionString=$STORAGE_CONN"
```

### Step 3 — Deploy

**From Visual Studio:**
1. Right-click project → Publish
2. Select "Azure" → "Azure App Service (Windows)"
3. Select your web app → Publish

**From CLI:**
```bash
dotnet publish -c Release -o ./publish
cd publish
zip -r ../app.zip .
az webapp deployment source config-zip \
  --name $WEB_APP \
  --resource-group $RESOURCE_GROUP \
  --src ../app.zip
```

### Step 4 — Run SQL Script on Azure

Using Azure Data Studio or SSMS, connect to your Azure SQL Server and run `EventEase_Database.sql`.

---

## Part D — Theory Questions

### D1: Cloud vs On-Premises Deployment

**Security:**
On-premises deployment requires an organisation to manage its own firewalls, patch cycles, intrusion detection, and physical security — a significant burden for a growing company like EventEase. Cloud platforms like Azure provide built-in security features including Azure Defender, DDoS protection, and automated patch management. For example, Azure SQL Database encrypts data at rest using Transparent Data Encryption (TDE) by default, whereas an on-premises SQL Server would require the DBA to configure this manually.

**Deployment Speed:**
On-premises requires procurement of hardware, OS installation, and configuration before a single line of code runs — typically weeks to months. Azure App Service allows EventEase to provision a web host in minutes via the portal or CLI. Continuous deployment pipelines (GitHub Actions → Azure) mean code changes can reach production in under 10 minutes, compared to manual deployment scripts on on-premises servers.

**Resource Management:**
On-premises resources are fixed — if EventEase experiences a spike in bookings before a major event, the system could degrade with no way to scale without purchasing new hardware. Azure provides auto-scaling: the App Service Plan can automatically add instances under load. Azure SQL also offers elastic scaling, allowing the DTU/vCore tier to be adjusted dynamically without downtime.

---

### D2: IaaS vs PaaS vs SaaS — Why PaaS for EventEase

| Model | You Manage | Provider Manages | Example |
|---|---|---|---|
| **IaaS** | OS, runtime, app, data | Hardware, networking, virtualisation | Azure VMs |
| **PaaS** | App code + data | OS, runtime, middleware, scaling | Azure App Service, Azure SQL |
| **SaaS** | Configuration only | Everything | Microsoft 365, Salesforce |

**Why PaaS is ideal for EventEase:**

*IaaS* (e.g., deploying on Azure VMs) would require EventEase's team to manage Windows Server updates, install .NET runtimes, configure IIS, and handle OS-level security. This is unsuitable for a company whose core competency is event management, not infrastructure administration.

*SaaS* solutions are too rigid — a generic booking SaaS product would not allow EventEase to build the exact booking logic (double-booking prevention, the custom consolidated view, Blob Storage integration) that the CEO's requirements specify.

**PaaS (Azure App Service + Azure SQL Database)** hits the sweet spot:
- EventEase developers deploy code; Azure handles the OS, patching, TLS certificates, and load balancing.
- Azure SQL Database provides automatic backups (meeting the CEO's requirement for "secure cloud storage with backups"), geo-replication, and point-in-time restore without a DBA managing the server.
- Azure Blob Storage (also PaaS) provides scalable, durable image storage without managing a file server.

This allows the small EventEase development team to focus entirely on building features rather than managing infrastructure.

---

### E1: Azure Cognitive Search vs Traditional Search

Traditional search engines (e.g., SQL `LIKE` queries, full-text search) work by exact or pattern matching against stored text. Azure Cognitive Search adds an **AI enrichment pipeline** that can extract meaning, entities, and key phrases from unstructured content.

**Advantages for EventEase scenarios:**
- Searching PDFs of venue contracts or scanned booking confirmations — Cognitive Search can OCR and index these.
- Fuzzy matching: a user typing "Johhanesburg" would still find Johannesburg venues, unlike a SQL `LIKE` query.
- Faceted navigation: auto-generate filters (by event type, capacity range, date) from indexed data.

**Limitations:**
- Cost: Cognitive Search incurs additional charges, especially for AI enrichment skills.
- Complexity: requires an indexer pipeline setup; not justified for simple table lookups.
- Latency: index refresh is not real-time — new bookings may not appear instantly.

**Mitigation:** Use Cognitive Search only for discovery features (venue browsing, document search), while keeping operational queries (booking conflict checks) in Azure SQL.

---

### E2: Database Normalisation in Cloud Environments

**Normalisation** organises data to eliminate redundancy and ensure referential integrity. EventEase's database is in **Third Normal Form (3NF)**:
- EventTypes extracted to a lookup table (not repeated as strings in Events).
- Venue details stored once in Venues, referenced by FK in Events and Bookings.

**Normalised (EventEase's approach) — benefits in Azure SQL:**
- Smaller row sizes → more rows per data page → fewer I/Os for queries.
- Updates propagate correctly (rename a venue once; all bookings reflect it).
- Azure SQL's Standard tier costs are based on DTUs; normalised schemas use fewer DTUs per operation.

**Denormalised structures:**
- Useful for read-heavy reporting scenarios (e.g., Azure Synapse Analytics, data warehouses).
- `vw_BookingDetails` is a *controlled denormalisation* — it presents joined data for the UI without physically duplicating data. This is a best-of-both-worlds pattern.

**Scalability consideration:** A normalised schema with proper indexing (as implemented — `IX_Events_VenueId`, `IX_Bookings_EventId`) scales well on Azure SQL. Denormalisation should only be introduced when query profiling proves a specific bottleneck, not preemptively.
