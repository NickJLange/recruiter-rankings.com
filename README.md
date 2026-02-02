# recruiter-rankings.com
Private Website for Recruiter Rankings.com



Open Question - Let Recruiters Rank you (Why not?)

## Developer Guidelines
For detailed architecture, setup, and contribution guidelines, please refer to [AGENTS.md](AGENTS.md).


#Recruiter Rankings Workflows
Data Objects

Company (URL, Sector, Industry, Name)
Person -> (Linked In, Email, Name)
Role -> (URL, Title, Description, Recruiting Company(Company), Target Company(Company), Date, Comp, RecruiterTake)
Security (Person, AccessToken (email, twillio, github etc))


Events 
Interaction -> (Recruiter (Person), Target(Person), Role, Experience)
Experience -> (Interaction, Rating, Experience, WouldRecommend)


Reports
Need Rate Limiting for Authenticated Humans / Bots

No-Auth - SourcingCompany, Roles, ExperienceReviewAggregate
AuthenticatedHuman - Two per month, Aggregate score for recruiterCompany 
AuthenticatedHuman - Search on email - five per day - Score for person across companies
AuthenticatedHuman - Search on LinkedIn - five per day
Score for person across companies

AuthenticatedBot - One per six months, Aggregate score for recruiterCompany 

PaidAuthenticatedHuman - 

OpenEmbeddings 


Recruiting Company
Time Recruiting (if we know)
Person -> (Linked In, Email, Name)
Recruiting For Company
Recruiting For Role
Aggregate Score

## Database Backups

Automated backups are handled via `BackupService` and can be triggered via Rake task or `ScheduledBackupJob`.

### Configuration
Set the following environment variables:
- `RENDER_API_KEY`: Render API key for database discovery.
- `RENDER_DB_NAME`: The name of the database on Render.
- `BACKUP_ENCRYPTION_KEY`: Secret key for AES-256 backup encryption.
- `BACKUP_RETENTION_DAYS`: How many days to keep backups (default: 7).
- `AWS_BUCKET`: (Optional) S3 bucket name for off-site storage.
- `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT`: S3 credentials.

### Manual Backup
```bash
DB_NAME=my-db rake db:backup:create
```

### Scheduling on Render
Add a "Cron Job" service on Render with the command:
```bash
bundle exec rake db:backup:create
```
Schedule it to run daily (e.g., `0 2 * * *`).

### Restore
1. Download the `.sql.gz.enc` file.
2. Decrypt: `openssl enc -d -aes-256-cbc -k $BACKUP_ENCRYPTION_KEY -in backup.enc -out backup.sql.gz`
3. Gunzip: `gunzip backup.sql.gz`
4. Restore: `psql $DATABASE_URL < backup.sql`




I show up with a Name, email, or company

Linked in URL -> Exact Match
Name -> Exact Match
Company Name -> Rolled-Up Match
