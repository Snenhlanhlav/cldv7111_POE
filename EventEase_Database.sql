-- ============================================================
--  EventEase Venue Booking System — Database Script
--  Compatible with: Azure SQL Database / SQL Server 2019+
-- ============================================================

USE master;
GO

-- Create database (skip if already exists / using Azure SQL)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'EventEaseDb')
BEGIN
    CREATE DATABASE EventEaseDb;
END;
GO

USE EventEaseDb;
GO

-- ── 1. EventTypes (lookup table) ────────────────────────────────────
IF OBJECT_ID('dbo.EventTypes', 'U') IS NOT NULL DROP TABLE dbo.EventTypes;
GO

CREATE TABLE dbo.EventTypes (
    EventTypeId INT          IDENTITY(1,1) PRIMARY KEY,
    TypeName    NVARCHAR(100) NOT NULL
);
GO

INSERT INTO dbo.EventTypes (TypeName) VALUES
    ('Conference'),
    ('Wedding'),
    ('Concert'),
    ('Corporate Function'),
    ('Birthday Party'),
    ('Exhibition'),
    ('Workshop'),
    ('Gala Dinner'),
    ('Sports Event'),
    ('Other');
GO

-- ── 2. Venues ────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Venues', 'U') IS NOT NULL DROP TABLE dbo.Venues;
GO

CREATE TABLE dbo.Venues (
    VenueId     INT            IDENTITY(1,1) PRIMARY KEY,
    VenueName   NVARCHAR(150)  NOT NULL,
    Location    NVARCHAR(250)  NOT NULL,
    Capacity    INT            NOT NULL CHECK (Capacity > 0),
    ImageUrl    NVARCHAR(500)  NULL,
    IsAvailable BIT            NOT NULL DEFAULT 1
);
GO

-- ── 3. Events ────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
GO

CREATE TABLE dbo.Events (
    EventId     INT           IDENTITY(1,1) PRIMARY KEY,
    EventName   NVARCHAR(150) NOT NULL,
    EventDate   DATETIME2     NOT NULL,
    EndDate     DATETIME2     NULL,
    Description NVARCHAR(1000) NULL,
    ImageUrl    NVARCHAR(500) NULL,
    VenueId     INT           NULL REFERENCES dbo.Venues(VenueId)     ON DELETE SET NULL,
    EventTypeId INT           NULL REFERENCES dbo.EventTypes(EventTypeId) ON DELETE SET NULL
);
GO

CREATE INDEX IX_Events_VenueId     ON dbo.Events (VenueId);
CREATE INDEX IX_Events_EventTypeId ON dbo.Events (EventTypeId);
GO

-- ── 4. Bookings ──────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Bookings', 'U') IS NOT NULL DROP TABLE dbo.Bookings;
GO

CREATE TABLE dbo.Bookings (
    BookingId   INT       IDENTITY(1,1) PRIMARY KEY,
    EventId     INT       NOT NULL REFERENCES dbo.Events(EventId)  ON DELETE NO ACTION,
    VenueId     INT       NOT NULL REFERENCES dbo.Venues(VenueId)  ON DELETE NO ACTION,
    BookingDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

    -- Prevent the same venue being booked for the same event twice
    CONSTRAINT UQ_Bookings_Venue_Event UNIQUE (VenueId, EventId)
);
GO

CREATE INDEX IX_Bookings_EventId ON dbo.Bookings (EventId);
CREATE INDEX IX_Bookings_VenueId ON dbo.Bookings (VenueId);
GO

-- ── 5. vw_BookingDetails (consolidated view) ─────────────────────────
CREATE OR ALTER VIEW dbo.vw_BookingDetails AS
SELECT
    b.BookingId,
    b.BookingDate,
    e.EventName,
    e.EventDate,
    e.EndDate,
    e.Description   AS EventDescription,
    e.ImageUrl      AS EventImageUrl,
    et.TypeName     AS EventTypeName,
    v.VenueName,
    v.Location,
    v.Capacity,
    v.ImageUrl      AS VenueImageUrl
FROM       dbo.Bookings   b
INNER JOIN dbo.Events     e  ON b.EventId     = e.EventId
INNER JOIN dbo.Venues     v  ON b.VenueId     = v.VenueId
LEFT  JOIN dbo.EventTypes et ON e.EventTypeId = et.EventTypeId;
GO

-- ── 6. Sample seed data ───────────────────────────────────────────────
INSERT INTO dbo.Venues (VenueName, Location, Capacity, IsAvailable) VALUES
    ('The Grand Pavilion',      '10 Nelson Mandela Square, Sandton, Johannesburg', 500,  1),
    ('Vineyard Estate',         '7 Helshoogte Road, Stellenbosch, Cape Town',       200,  1),
    ('Durban ICC Hall A',       '45 Bram Fischer Rd, Durban',                       1500, 1),
    ('Melrose Arch Conference', '1 Melrose Blvd, Melrose Arch, Johannesburg',        300,  1),
    ('The Barn at Hartbeespoort','22 Hartbeespoort Dam Rd, North West',             150,  0);
GO

INSERT INTO dbo.Events (EventName, EventDate, EndDate, Description, VenueId, EventTypeId) VALUES
    ('TechSummit 2025',      '2025-09-15 09:00', '2025-09-16 17:00', 'Annual technology conference.', 1, 1),
    ('Smith Wedding',        '2025-10-04 14:00', '2025-10-04 23:00', 'Wedding reception.',            2, 2),
    ('Afrojam Festival',     '2025-11-22 18:00', '2025-11-22 23:59', 'Live music festival.',          3, 3),
    ('Q4 Strategy Day',      '2025-09-30 08:30', '2025-09-30 17:00', 'Annual strategy planning.',     4, 4),
    ('Product Launch 2026',  '2026-01-20 10:00', NULL,               'New product launch event.',     NULL, 4);
GO

INSERT INTO dbo.Bookings (EventId, VenueId, BookingDate) VALUES
    (1, 1, GETUTCDATE()),
    (2, 2, GETUTCDATE()),
    (3, 3, GETUTCDATE()),
    (4, 4, GETUTCDATE());
GO

PRINT 'EventEase database created and seeded successfully.';
GO
