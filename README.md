
```bash
sudo ./wireguardDB.sh -a alice 10.0.0.2
```
- Creates a new WireGuard peer named `ALICE`
- Generates a key pair
- Adds configuration to `wg0.conf`
- Saves data to `wgPeers.db`
- Prints the private key once (make sure to copy it)

### ➖ Delete a Peer
```bash
sudo ./wireguardDB.sh -d alice
```
- Removes peer `ALICE` from both:
- WireGuard config file
- SQLite database

### 📋 List All Peers
```bash
sudo ./wireguardDB.sh -l
```
Outputs a table of all peers currently stored in the database

## ⚠️ Requirements
- Bash
- WireGuard (wg command)
- SQLite3