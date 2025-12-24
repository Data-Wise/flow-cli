/**
 * WebDashboard
 *
 * Express server with WebSocket support for real-time dashboard updates.
 * Serves a single-page HTML dashboard with live session monitoring.
 *
 * Features:
 * - Real-time session updates via WebSocket
 * - REST API for status data
 * - Auto-refresh on session events
 * - Single-file HTML dashboard (no build step)
 */

import express from 'express'
import { WebSocketServer } from 'ws'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

export class WebDashboard {
  /**
   * @param {GetStatusUseCase} getStatusUseCase
   * @param {SimpleEventPublisher} eventPublisher
   */
  constructor(getStatusUseCase, eventPublisher) {
    this.getStatus = getStatusUseCase
    this.eventPublisher = eventPublisher
    this.app = express()
    this.wss = null
    this.server = null
    this.clients = new Set()
  }

  /**
   * Start the web server and WebSocket server
   * @param {number} port - Port to listen on (default: 3737)
   * @returns {Promise<string>} URL of the dashboard
   */
  async start(port = 3737) {
    // Serve static files from public directory
    const __dirname = dirname(fileURLToPath(import.meta.url))
    this.app.use(express.static(join(__dirname, 'public')))

    // API endpoint for status data
    this.app.get('/api/status', async (req, res) => {
      try {
        const status = await this.getStatus.execute()
        res.json({
          success: true,
          status
        })
      } catch (error) {
        res.status(500).json({
          success: false,
          error: error.message
        })
      }
    })

    // Health check endpoint
    this.app.get('/api/health', (req, res) => {
      res.json({ status: 'ok', clients: this.clients.size })
    })

    // Start HTTP server
    this.server = this.app.listen(port)

    // Setup WebSocket server
    this.wss = new WebSocketServer({ server: this.server })

    this.wss.on('connection', ws => {
      this.clients.add(ws)

      // Send initial status immediately
      this.sendStatus(ws)

      // Subscribe to session events
      const sessionUpdatedListener = () => this.sendStatus(ws)
      const sessionCreatedListener = () => this.sendStatus(ws)
      const sessionEndedListener = () => this.sendStatus(ws)

      this.eventPublisher.on('session:updated', sessionUpdatedListener)
      this.eventPublisher.on('session:created', sessionCreatedListener)
      this.eventPublisher.on('session:ended', sessionEndedListener)

      // Cleanup on disconnect
      ws.on('close', () => {
        this.clients.delete(ws)
        this.eventPublisher.off('session:updated', sessionUpdatedListener)
        this.eventPublisher.off('session:created', sessionCreatedListener)
        this.eventPublisher.off('session:ended', sessionEndedListener)
      })

      // Handle errors
      ws.on('error', error => {
        console.error('WebSocket error:', error.message)
        this.clients.delete(ws)
      })
    })

    return `http://localhost:${port}`
  }

  /**
   * Send current status to a WebSocket client
   * @param {WebSocket} ws - WebSocket client
   */
  async sendStatus(ws) {
    try {
      const status = await this.getStatus.execute()

      if (ws.readyState === 1) {
        // OPEN
        ws.send(
          JSON.stringify({
            type: 'status',
            data: status,
            timestamp: new Date().toISOString()
          })
        )
      }
    } catch (error) {
      if (ws.readyState === 1) {
        ws.send(
          JSON.stringify({
            type: 'error',
            error: error.message,
            timestamp: new Date().toISOString()
          })
        )
      }
    }
  }

  /**
   * Broadcast status update to all connected clients
   */
  async broadcast() {
    const status = await this.getStatus.execute()
    const message = JSON.stringify({
      type: 'status',
      data: status,
      timestamp: new Date().toISOString()
    })

    for (const client of this.clients) {
      if (client.readyState === 1) {
        // OPEN
        client.send(message)
      }
    }
  }

  /**
   * Stop the web server and close all connections
   */
  stop() {
    // Close all WebSocket connections
    for (const client of this.clients) {
      client.close()
    }
    this.clients.clear()

    // Close WebSocket server
    if (this.wss) {
      this.wss.close()
      this.wss = null
    }

    // Close HTTP server
    if (this.server) {
      this.server.close()
      this.server = null
    }
  }

  /**
   * Get server info
   */
  getInfo() {
    return {
      port: this.server?.address()?.port,
      clients: this.clients.size,
      running: this.server !== null
    }
  }
}
