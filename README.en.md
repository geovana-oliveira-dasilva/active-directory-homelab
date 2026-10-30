# Active Directory Home Lab

![Windows Server 2022](https://img.shields.io/badge/Windows%20Server-2022-0078D6?logo=windows&logoColor=white)
![Windows 11](https://img.shields.io/badge/Windows-11%20Enterprise-0078D6?logo=windows11&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-7.2-183A61?logo=virtualbox&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?logo=powershell&logoColor=white)
![Status](https://img.shields.io/badge/Status-in%20progress-yellow)

[Deutsch](README.md) | **English**

A virtual Windows domain environment with **Windows Server 2022** (AD DS, DNS, DHCP, NAT) and a **Windows 11 client**, built and documented from scratch. The project is hands-on preparation for an apprenticeship (Ausbildung) as an **IT Specialist for System Integration** (Fachinformatiker/in für Systemintegration).

---

## Contents

- [Project overview](#project-overview)
- [Skills](#skills)
- [Architecture](#architecture)
- [Implementation](#implementation)
- [Challenges and solutions](#challenges-and-solutions)
- [Security](#security)
- [Lessons learned](#lessons-learned)
- [Next steps](#next-steps)
- [Repository structure](#repository-structure)

---

## Project overview

**Goal:** Recreate a small company environment like those found in many businesses running Windows infrastructure, and install, configure and understand the core services myself.

**Result:**

- Domain Controller `DC01` with the new forest **`oliveira.com`**
- DNS (AD-integrated) and DHCP for the internal network
- Internet access for internal clients through **NAT** (Routing and Remote Access)
- Custom organizational units and a separate administrator account
- Automated creation of several hundred users with **PowerShell**
- Windows 11 client `CLIENT01` on the internal network

---

## Skills

| Area | Implementation in the lab |
|---|---|
| Virtualization | Two VMs in VirtualBox, NAT network and internal network |
| Windows Server | Installing Windows Server 2022, managing roles through Server Manager |
| Directory services | AD DS, new forest, organizational units, users and groups |
| Networking | Static IP addressing, `/24` subnet, DNS, DHCP, NAT and routing |
| Automation | PowerShell script for bulk user account creation |
| IT security | Separate admin account, Execution Policy, no plain-text passwords |
| Troubleshooting | Identified an APIPA address, fixed an Execution Policy error |
| Documentation | Step-by-step documentation with screenshots (this repository) |

---

## Architecture

```mermaid
flowchart LR
    NET((Internet)) --- NATVB[VirtualBox NAT<br/>built-in DHCP]
    NATVB ---|"INTERNET<br/>10.0.2.15 (DHCP)"| DC
    subgraph DC["DC01 · Windows Server 2022<br/>AD DS · DNS · DHCP · RRAS/NAT"]
    end
    DC ---|"INTERNAL<br/>172.16.0.1/24"| SW[Internal network<br/>intnet]
    SW --- CL["CLIENT01 · Windows 11<br/>IP via DHCP<br/>172.16.0.100–200"]
```

### Virtual machines

| VM | Operating system | RAM | vCPU | Network |
|---|---|---|---|---|
| DC01 | Windows Server 2022 Standard Evaluation (Desktop Experience) | 2 GB | 2 | NAT + internal network |
| CLIENT01 | Windows 11 Enterprise Evaluation | 2 GB | 2 | Internal network only |

### Network plan

| Item | Value |
|---|---|
| Domain | `oliveira.com` (NetBIOS: `OLIVEIRA`) |
| Domain Controller | `DC.oliveira.com` |
| External interface (INTERNET) | VirtualBox NAT, `10.0.2.15` via DHCP |
| Internal interface (INTERNAL) | `172.16.0.1` / `255.255.255.0`, DNS `127.0.0.1` |
| DHCP scope | `172.16.0.100` – `172.16.0.200` |
| DNS for clients | `172.16.0.1` |

---

## Implementation

### 1. Preparation and Domain Controller VM

I downloaded VirtualBox (with the Extension Pack) and the evaluation ISOs for Windows Server 2022 and Windows 11 Enterprise (both 64-bit). Then I created the VM **DC01**: 2 GB RAM, 2 vCPUs, a 50 GB disk and two network adapters (NAT and internal network).

![Creating the DC01 VM](screenshots/02-dc01-vm-create.png)

<details>
<summary>More screenshots</summary>

![Downloads](screenshots/01-downloads.png)

![DC01 VM summary](screenshots/03-dc01-vm-summary.png)

</details>

### 2. Installing Windows Server 2022

I chose the **Standard Evaluation (Desktop Experience)** edition. Without Desktop Experience the server is installed as Server Core and managed from the command line only. For getting started, the graphical interface makes each step easier to understand; for tasks at scale, the command line (PowerShell) is the right tool, see step 8.

![Choosing Desktop Experience](screenshots/04-server-desktop-experience.png)

### 3. Server network configuration

I renamed the network adapters to **INTERNET** and **INTERNAL** for clarity. The internal adapter first had an APIPA address (`169.254.x.x`) because there was no DHCP server on the internal network yet. Since the server becomes the Domain Controller, it got a **static IP address** and points to itself as its DNS server.

![Static IP on the internal adapter](screenshots/06-internal-static-ip.png)

<details>
<summary>More screenshots</summary>

![Renamed network adapters](screenshots/05-network-adapters.png)

</details>

### 4. Active Directory Domain Services

Through **Server Manager → Add Roles and Features** I installed AD DS and promoted the server to Domain Controller of a **new forest `oliveira.com`**. The DNS server is installed automatically along with it, because Active Directory depends on DNS.

![New forest oliveira.com](screenshots/08-adds-new-forest.png)

<details>
<summary>More screenshots</summary>

![AD DS role](screenshots/07-adds-role.png)

![Review options](screenshots/09-adds-review.png)

![Prerequisites check](screenshots/10-adds-prerequisites.png)

</details>

### 5. Organizational unit and administrator account

In **Active Directory Users and Computers** I created the OU **ADMS** and, inside it, a personal administrator account that is a member of **Domain Admins**. The built-in `Administrator` account is no longer used for daily work.

![ADMS OU with administrator account](screenshots/11-adms-ou-admin-user.png)

<details>
<summary>More screenshots</summary>

![Domain Admins membership](screenshots/12-domain-admins-membership.png)

</details>

### 6. Routing and NAT (RRAS)

So that clients on the internal network can reach the internet, I installed the **Remote Access** role with the **Routing** role service. In the **Routing and Remote Access** console I configured **NAT**, with the INTERNET adapter as the public interface. NAT lets many internal clients communicate through a single public IP address.

![NAT configuration](screenshots/15-rras-nat.png)

<details>
<summary>More screenshots</summary>

![Remote Access role](screenshots/13-remote-access-role.png)

![Routing role service](screenshots/14-routing-role-service.png)

![Public interface](screenshots/16-rras-public-interface.png)

![Server Manager with installed roles](screenshots/17-server-manager-roles.png)

</details>

### 7. DHCP server

I installed the **DHCP Server** role on the Domain Controller and created the scope `172.16.0.100–172.16.0.200` (`/24`). The scope options hand out the domain `oliveira.com` and the DNS server `172.16.0.1` to the clients.

![DHCP scope](screenshots/19-dhcp-scope-range.png)

<details>
<summary>More screenshots</summary>

![DHCP Server role](screenshots/18-dhcp-role.png)

![Lease duration](screenshots/20-dhcp-lease.png)

![Scope DNS options](screenshots/21-dhcp-dns-options.png)

</details>

### 8. Bulk user creation with PowerShell

The script [`scripts/Create-BulkADUsers.ps1`](scripts/Create-BulkADUsers.ps1) reads names from `names.txt`, creates the OU `_USERS` and creates one account per name using the pattern *first letter of the first name + last name* (e.g. `abirk`). The initial password is requested at run time and is not stored in the script.

```powershell
$password = Read-Host -Prompt "Initial password for the users" -AsSecureString
New-ADOrganizationalUnit -Name _USERS -ProtectedFromAccidentalDeletion $false

foreach ($n in Get-Content .\names.txt) {
    $first    = $n.Split(" ")[0].ToLower()
    $last     = $n.Split(" ")[1].ToLower()
    $username = "$($first.Substring(0,1))$($last)"
    New-ADUser -Name $username -GivenName $first -Surname $last `
               -AccountPassword $password -Enabled $true `
               -Path "ou=_USERS,$(([ADSI]`"").distinguishedName)"
}
```

![Users created by the script](screenshots/23-powershell-bulk-users.png)

<details>
<summary>More screenshots</summary>

![Execution Policy error](screenshots/22-powershell-execution-policy.png)

</details>

### 9. Client VM

The VM **CLIENT01** running Windows 11 Enterprise is connected only to the internal network `intnet`. It therefore depends entirely on the Domain Controller for its IP address (DHCP), name resolution (DNS) and internet access (NAT).

![CLIENT01 network](screenshots/25-client01-internal-network.png)

<details>
<summary>More screenshots</summary>

![CLIENT01 hardware](screenshots/24-client01-vm.png)

</details>

---

## Challenges and solutions

| Problem | Cause | Solution |
|---|---|---|
| Internal adapter with address `169.254.x.x` | APIPA: Windows found no DHCP server on the internal network | Static IP `172.16.0.1/24` on the DC; DHCP server set up for the clients |
| PowerShell script blocked ("not digitally signed") | Execution Policy does not allow unsigned scripts | Adjusted the Execution Policy (safer: `Set-ExecutionPolicy Bypass -Scope Process`) |
| Warnings in the prerequisites check (DNS delegation, IPv6) | Isolated lab domain with no parent DNS zone, IPv6 not statically configured | Reviewed and deliberately accepted; not critical for a lab |
| Internal clients without internet access | The internal network has no gateway of its own | NAT through RRAS on the DC, INTERNET adapter as the public interface |

---

## Security

- **No sensitive data in the repository:** the script asks for the password at run time, and passwords and personal paths are blurred in the screenshots.
- **Separate administrator account** instead of the built-in `Administrator` account.
- **Lab only:** `PasswordNeverExpires` and a relaxed Execution Policy would not be acceptable in production. There you would use strong passwords, a forced change at first logon (`-ChangePasswordAtLogon $true`) and password policies via GPO.

---

## Lessons learned

- Active Directory does not work without correct DNS. That is why the DC points to itself and hands out its own IP as the DNS server.
- An APIPA address is a clear sign of a missing or unreachable DHCP server.
- The graphical interface helps with learning; PowerShell is essential for repeated tasks and tasks at scale.
- In the lab the Domain Controller runs many roles at once (DNS, DHCP, NAT). AD FS and IIS were also installed for testing. In production you would separate roles and install only what is needed on the DC to keep the attack surface small.
- For real environments, a subdomain of a registered company domain (e.g. `ad.company.com`) is the recommended domain name.

---

## Next steps

- [ ] Join CLIENT01 to the `oliveira.com` domain
- [ ] Verify the DHCP lease (`ipconfig /all`) and internet access on the client
- [ ] Log on to the client with a user created by the script
- [ ] Create Group Policies (GPO), e.g. password policy and drive mapping
- [ ] Security groups and NTFS permissions on file shares

---

## Repository structure

```
├── README.md                      Deutsch
├── README.en.md                   English
├── scripts/
│   └── Create-BulkADUsers.ps1     PowerShell script for user creation
└── screenshots/                   Screenshots of each step
```

> Note: all systems run only in an isolated lab environment with Microsoft evaluation licenses.
