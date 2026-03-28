// PM2 Ecosystem Configuration
// Auto-scaling: runs one worker per CPU core in cluster mode.
//
// Usage:
//   npm install -g pm2
//   pm2 start ecosystem.config.js
//   pm2 monit              (monitor)
//   pm2 scale careshift +2 (add 2 more workers)
//   pm2 reload careshift   (zero-downtime restart)

module.exports = {
    apps: [
        {
            name: 'careshift',
            script: 'server.js',
            instances: 'max',          // Use all CPU cores
            exec_mode: 'cluster',      // Cluster mode for load balancing
            watch: false,
            max_memory_restart: '500M',
            env: {
                NODE_ENV: 'development',
                PORT: 5000,
            },
            env_production: {
                NODE_ENV: 'production',
                PORT: 5000,
            },
            // Graceful shutdown
            kill_timeout: 5000,
            listen_timeout: 10000,
            // Logging
            error_file: './logs/pm2-error.log',
            out_file: './logs/pm2-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
            merge_logs: true,
        },
    ],
};
