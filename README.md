# BitLocker-Key-Existence-Checker-for-Microsoft-Entra-ID
A PowerShell script that provides compliance-safe visibility into BitLocker recovery key escrow status in Microsoft Entra ID (formerly Azure AD).
This script helps organizations audit and verify that BitLocker recovery keys are properly escrowed to Microsoft Entra ID without exposing sensitive cryptographic information. It answers the critical question: "Which devices have BitLocker keys safely stored in the cloud?"

🔒 Compliance & Security

✅ Fully Compliant Design

READ-ONLY operations - Never modifies or regenerates keys
No sensitive data exposure - Never retrieves actual recovery keys or key IDs
Metadata only - Shows existence confirmation, creation dates, and device info
Audit-friendly - Creates appropriate audit trail without security risks

🛡️ What is NOT Retrieved

❌ Actual BitLocker recovery keys

❌ BitLocker Key IDs or identifiers

❌ Any cryptographic material

❌ Sensitive security information

✅ What IS Retrieved

✅ Key existence confirmation ("Yes" vs "No")

✅ Device names and basic information

✅ Key creation timestamps

✅ Volume types (OS drive vs Data drive)

✅ Device trust relationships

🚀 Features

Comprehensive Device Matching

Multiple matching algorithms to maximize device name resolution
Handles hybrid-joined, cloud-joined, and registered devices
Fallback methods for complex enterprise environments

Detailed Reporting

CSV export for further analysis
Summary statistics and insights
Volume type breakdown (OS drives vs Data drives)
Device trust type analysis
Matching success rates

Enterprise-Ready

Handles large environments (tested with 1000+ devices)
Progress indicators for long-running operations
Robust error handling and logging
Minimal required permissions

📋 Prerequisites
Required Azure AD App Registration Permissions

BitLockerKey.ReadBasic.All (Application)

Device.Read.All (Application)

PowerShell Modules

Microsoft.Graph.Authentication
Microsoft.Graph.Identity.SignIns
Microsoft.Graph.Identity.DirectoryManagement

Note: Script will automatically install missing modules

🛠️ Installation & Usage

1. Clone Repository

2. Configure Credentials
Edit the script and replace placeholders:

powershell$tenantId = "YOUR_TENANT_ID"

$clientId = "YOUR_CLIENT_ID" 

$clientSecret = "YOUR_CLIENT_SECRET"

4. Run Script

powershell.\BitLocker-Key-Checker.ps1

📊 Sample Output

Console Summary

BITLOCKER KEY SUMMARY

Total keys found: 1177

Unique devices: 856

Volume Types:

  1: 1046  (OS Drives)
  
  2: 131   (Data Drives)
  

Device Matching Results:

  Direct DeviceId: 800
  
  Entra ID Object Id: 200
  
  No Match: 177
  

Devices with BitLocker keys:

  ✓ LAPTOP-ABC123
  
  ✓ DESKTOP-XYZ789
  
  ✓ SERVER-DEF456
CSV Report Columns

ColumnDescriptionDeviceNameDevice display nameDeviceIdEntra ID device identifierHasBitLockerKeyConfirmation ("Yes")KeyExistsStatus ("Confirmed")VolumeType1=OS Drive, 2=Data DriveKeyCreatedDateTimeWhen key was escrowedDeviceOSOperating systemDeviceTrustTypeJoin method (Azure AD, Hybrid, etc.)MatchMethodHow device was identified

🔍 Understanding Results

Volume Types Explained

Type 1: Operating System drives (C: drive with Windows)

Type 2: Fixed data drives (additional internal drives)

Type 3: Removable drives (rare in reports)


Multiple Keys Per Device

Having multiple BitLocker keys for the same device is normal and indicates:

✅ Key rotation for security compliance

✅ Policy-driven key regeneration

✅ System updates triggering new keys

✅ Proper security hygiene


Device Matching Success

Direct DeviceId: Standard successful match

Entra ID Object Id: Alternative successful match method

No Match: Keys from deleted devices or permission issues


⚠️ Important Notes
Safe Operation

This script NEVER damages or regenerates BitLocker keys
Read-only operations ensure zero impact on production systems
Equivalent to viewing file properties without opening files

Performance Considerations

Large environments (1000+ devices) may take 10-15 minutes
Progress indicators show real-time status
Consider running during maintenance windows for very large deployments

Troubleshooting

No keys found: Verify permissions and BitLocker policy configuration
Many "Unknown" devices: Check Device.Read.All permission
Authentication errors: Verify app registration and client secret

📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Areas for Enhancement

Additional device matching algorithms

Export format options (Excel, JSON)

Integration with compliance frameworks

Automated reporting schedules

📞 Support

For issues or questions:

Check existing Issues

Create a new issue with detailed information

Include sanitized error messages (remove sensitive data)

🏷️ Version History

v1.0.0: Initial release with compliance-safe reporting
Enhanced device matching algorithms
CSV export functionality
Comprehensive error handling


⚡ Pro Tip: Run this script monthly to maintain visibility into your BitLocker key escrow status and ensure compliance with data protection policies!
