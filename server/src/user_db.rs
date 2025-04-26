use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;
use std::sync::{Arc, Mutex};
use tokio::fs;

#[derive(Debug, Clone)]
pub struct UserDatabase {
    users: Arc<Mutex<HashMap<String, String>>>,
}

#[derive(Serialize, Deserialize)]
struct UserDatabaseFile {
    users: HashMap<String, String>,
}

impl UserDatabase {
    pub fn new() -> Self {
        Self {
            users: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub async fn load<P: AsRef<Path>>(path: P) -> Result<Self> {
        let db = if let Ok(content) = fs::read_to_string(path).await {
            let db_file: UserDatabaseFile = serde_json::from_str(&content)?;
            Self {
                users: Arc::new(Mutex::new(db_file.users)),
            }
        } else {
            Self::new()
        };

        Ok(db)
    }

    pub async fn save<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let users = self.users.lock().unwrap().clone();
        let db_file = UserDatabaseFile { users };

        let content = serde_json::to_string_pretty(&db_file)?;
        fs::write(path, content).await?;

        Ok(())
    }

    pub fn add_user(&mut self, username: String, password: String) {
        let mut users = self.users.lock().unwrap();
        users.insert(username, password);
    }

    pub fn authenticate(&self, username: &str, password: &str) -> bool {
        let users = self.users.lock().unwrap();
        
        if let Some(stored_password) = users.get(username) {
            stored_password == password
        } else {
            false
        }
    }

    pub fn remove_user(&mut self, username: &str) -> bool {
        let mut users = self.users.lock().unwrap();
        users.remove(username).is_some()
    }
} 