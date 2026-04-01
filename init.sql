-- Goldsky-managed schema (tables created automatically by pipeline sinks)
CREATE SCHEMA IF NOT EXISTS indexer;

-- App-managed views for frontend queries

-- Deposit tracking: latest status per request
CREATE OR REPLACE VIEW indexer.deposit_status AS
SELECT
  event_params[1] AS request_id,
  event_signature,
  CASE
    WHEN event_signature = 'DepositRefunded' THEN 'Refunded'
    WHEN event_signature = 'DepositClaimed' THEN 'Claimed'
    WHEN event_signature = 'DepositReadyToClaim' THEN 'ReadyToClaim'
    WHEN event_signature = 'DepositRequested' THEN 'Pending'
  END AS status,
  event_params[2] AS depositor_or_note_id,
  event_params[3] AS amount_or_token_id,
  block_timestamp,
  transaction_hash
FROM indexer.vault_events
ORDER BY block_number DESC, log_index DESC;

-- Note lifecycle: all state transitions
CREATE OR REPLACE VIEW indexer.note_lifecycle AS
SELECT
  event_params[1] AS note_id,
  event_signature,
  event_params,
  block_timestamp,
  transaction_hash
FROM indexer.engine_events
ORDER BY block_number ASC, log_index ASC;

-- Active coupon streams
CREATE OR REPLACE VIEW indexer.coupon_activity AS
SELECT
  event_signature,
  event_params,
  block_timestamp,
  transaction_hash
FROM indexer.streamer_events
ORDER BY block_number DESC, log_index DESC;

-- Note token holdings
CREATE OR REPLACE VIEW indexer.note_holdings AS
SELECT
  event_params[1] AS note_id,
  event_params[2] AS holder,
  event_params[3] AS amount,
  event_signature,
  block_timestamp
FROM indexer.notetoken_events
ORDER BY block_number DESC, log_index DESC;
