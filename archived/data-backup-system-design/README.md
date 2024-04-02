# Recolic Data Backup System

> A MULTI-LEVEL AUTOMATIC data backup management system.

## Design note

### Key and key management

GPG Key A, encrypt all confidential files without Type X flag.

GPG Key A is my daily GPG Key, holds one replica in RECOLICPC, another replica in RECOLICMPC, extra two replica managed by TypeX. All of there replicas are encrypted with Super password.

All key that vital for this backuping system is Type X. (GPG Key A, AWS AccessKey, Password Generator seed)

### File type

> "Important" means more protect against data loss, "confidential" means more protect against data leak.

Virtual tag, APPEND-ONLY -> files are large and almost never be read. It's hard and slow to retrive files, which must be done manually.

Virtual tag, PUBLIC -> files published to Internet, usually with an http endpoint. The http sharing may not be reliable at all, but it's there.

Virtual tag, NO-REPLICA -> files are too large to fit RAID replica. So only one copy will be kept in my system.

Virtual tag, SPECIAL-REPLICA -> files are too confidential to fit normal RAID replica. So all replica will be kept in a more secure place.

> I will have a RAID drive as home NAS. All files without 'NO-REPLICA' and 'SPECIAL-REPLICA' will be saved in home RAID. Where RAID 0Z1 holds two replica.

Type P : PUBLIC -> not confidential at all and already made public. usually large files. For example, open source datasets, system images, game installer images. Only 2 replica in RAID.

Type X : SPECIAL-REPLICA -> extremely confidential, life-attached file. For example, anti-police, anti-gov, leaked database files. Hold 2 highest level replica, with encrypted filename. MUST BE symmetric encrypted.

Type B: APPEND-ONLY, NO-REPLICA -> backup file for a working system. For example, RECOLICPC monthly full backup, recolic.net daily full backup, mcserver backup.

Type N -> important private files, no disaster upon data leak, but bad upon data loss. For example, private photos & videos, homeworks/reports waiting for sale. 3 replica.

Type M -> confidential private files, maybe a disaster upon leak. It must be encrypted with KeyA and converted to Type N. For example, ssh private key, BTC/ETH private key, kdbx database, scanned idcard/passport/visa without watermark.

![](https://github.com/recolic/data-backup-system/raw/master/img.png)

### User Interface

- N

Put N files directly to home NAS through NFS. 

- M

Run `rgpg-encrypt`, and put the encrypted N files directly to NAS through NFS.

- B

Run `rbackup b <localFilename>`, and it will initiate aws client automatically, partition it and upload to glacier.

Note: maybe I want to place B file NAS non-replica area. That's enough.

- P

Put P files directly to home NAS directory `/rpc_downloads`. Home http server will publish it automatically.

We usually use NAS to download P files from Internet to `/rpc_downloads` with HTTP/P2P/BaiduYun RPC directly.

- X

Manually managed. Manually upload after encrypted with gpg symmetric.

- AutoBackup


### File Storage Plan

> adjusted. convert X to M.

- LocalPC DISK

- Home NAS

Contains Type NP files.

NAS server runs cron job to fetch files from server/pc, and push to glacier automatically. Erase the old backup.

- REMOTE BACKUP 1, Storage server, FULL BACKUP, romania

Rsync (no delete), pull files from home NAS server every day. 

TODO: Do snapshot.

- REMOTE BACKUP 2, secret server, us

Contains X backup 1.

- REMOTE BACKUP 3, AWS S3 Glacier

Contains B file.

- REMOTE BACKUP 4, secret server, non-us/PRchina/taiwan location

Contains X backup 2.





