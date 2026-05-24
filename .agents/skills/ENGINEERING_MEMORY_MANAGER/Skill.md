---
name: "engineering-memory-manager"
description: "Engineers memory management skill responsible for cold/hot log system, long-term memory, ADR, failure history, execution status, and architectural decisions."
---

# ENGINEERING_MEMORY_MANAGER

## Layer Assignment

**Layer 0 — Memory**

## Responsibilities

- **Hot/Cold Log System** (Hot/Cold Log System)
- **Long-term Memory** (Long-term Memory)
- **ADR** (Architecture Decision Records)
- **Failure History** (Failure History)
- **Execution Status** (Execution Status)
- **Architectural Decisions** (Architectural Decisions)

## Memory Layers

### HOT (1 Day)
- Logs from the last 24 hours
- Fast access
- Uncompressed
- Used for real-time monitoring and quick retrieval

### WARM (3 Days)
- Logs from 1-3 days ago
- Medium access speed
- Compressed storage
- Used for recent historical analysis

### COLD (7 Days)
- Logs from 3-7 days ago
- Archival storage
- High compression ratio
- Used for historical audit and compliance

## Three-Color Log System

### Red Logs
- Errors and failures
- Immediate attention required
- Triggers alerts

### Yellow Logs
- Warnings and potential issues
- Require periodic review
- Trend analysis

### Green Logs
- Normal operations
- Status updates
- Successful completions

## Key Features

1. **Automatic Log Rotation** - Automatic archiving based on time
2. **Intelligent Compression** - Adjust compression strategy based on access frequency
3. **Fast Retrieval** - Supports full-text search and filtering
4. **Lifecycle Management** - Automatic cleanup of expired logs
5. **ADR Integration** - Automatic association with architecture decision records

## Output Artifacts

- `.agents/logs/hot/` - Real-time log directory (Fast Thinking reads)
- `.agents/logs/warm/` - Recent log directory
- `.agents/logs/cold/` - Archived log directory (Slow Thinking reads)
- `.agents/context/architecture_summary.md` - Architecture decision records
- `.agents/context/compressed_history.md` - Failure history records
- `.agents/state/execution_state.json` - Execution status

## State Management

This skill also manages:
- `.agents/state/current_phase.json` - Current workflow phase
- `.agents/state/active_tasks.json` - Active task tracking
- `.agents/state/blocked_tasks.json` - Blocked task registry
- `.agents/state/risk_registry.json` - Risk tracking

## Context Protocol

### For Slow Thinking (GPT)
- Read `.agents/logs/cold/` for historical context
- Read `.agents/context/` for compressed long-term memory

### For Fast Thinking (Codex/DeepSeek)
- Read `.agents/logs/hot/` for recent context
- Read `.agents/state/` for current execution state
