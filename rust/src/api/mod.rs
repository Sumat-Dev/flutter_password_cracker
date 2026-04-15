use sha2::{Sha256, Digest};
use flutter_rust_bridge::frb;
use crate::frb_generated::StreamSink;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Instant;

pub struct CrackProgress {
    pub current_attempt: String,
    pub total_attempts: u64,
    pub hashes_per_sec: f64,
    pub elapsed_secs: f64,
    pub is_found: bool,
    pub result: Option<String>,
}

#[frb(sync)]
pub fn hash_string(input: String) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    format!("{:x}", hasher.finalize())
}

pub fn brute_force_crack(
    target_hash: String,
    sink: StreamSink<CrackProgress>,
) {
    let counter = Arc::new(AtomicU64::new(0));
    let start = Instant::now();

    // a-z
    const CHARSET: &[u8] = b"abcdefghijklmnopqrstuvwxyz";

    let mut length = 1usize;
    let max_length = 5;

    'outer: loop {
        if length > max_length {
            let elapsed = start.elapsed().as_secs_f64();
            let c = counter.load(Ordering::Relaxed);
            let _ = sink.add(CrackProgress {
                current_attempt: "Finished (Max 5)".to_string(),
                total_attempts: c,
                hashes_per_sec: c as f64 / elapsed.max(0.001),
                elapsed_secs: elapsed,
                is_found: false,
                result: None,
            });
            return;
        }

        let total = (CHARSET.len() as u128).pow(length as u32);

        for i in 0..total {
            let candidate = index_to_string(i as usize, length, CHARSET);
            let c = counter.fetch_add(1, Ordering::Relaxed) + 1;

            let hash = compute_hash(candidate.as_bytes());

            if hash == target_hash {
                let elapsed = start.elapsed().as_secs_f64();
                let _ = sink.add(CrackProgress {
                    current_attempt: candidate.clone(),
                    total_attempts: c,
                    hashes_per_sec: c as f64 / elapsed.max(0.001),
                    elapsed_secs: elapsed,
                    is_found: true,
                    result: Some(candidate),
                });
                return;
            }

            if c % 50_000 == 0 {
                let elapsed = start.elapsed().as_secs_f64();
                if sink.add(CrackProgress {
                    current_attempt: candidate,
                    total_attempts: c,
                    hashes_per_sec: c as f64 / elapsed.max(0.001),
                    elapsed_secs: elapsed,
                    is_found: false,
                    result: None,
                }).is_err() {
                    return;
                }
            }
        }

        length += 1;
    }
}

fn compute_hash(input: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input);
    format!("{:x}", hasher.finalize())
}

fn index_to_string(mut index: usize, length: usize, charset: &[u8]) -> String {
    let mut bytes = vec![0u8; length];
    for i in (0..length).rev() {
        bytes[i] = charset[index % charset.len()];
        index /= charset.len();
    }
    String::from_utf8(bytes).unwrap()
}
