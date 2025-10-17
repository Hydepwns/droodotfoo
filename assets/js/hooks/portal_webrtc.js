/**
 * Portal WebRTC Hook for P2P connections
 * 
 * Handles:
 * - WebRTC peer connections
 * - Data channel management
 * - ICE candidate exchange
 * - Connection state tracking
 * - File transfer via data channels
 */

export const PortalWebRTCHook = {
  mounted() {
    this.connections = new Map();
    this.dataChannels = new Map();
    this.iceServers = [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' },
      { urls: 'stun:stun2.l.google.com:19302' }
    ];

    // Listen for LiveView events
    this.handleEvent('create_peer_connection', ({ connection_id, peer_id, portal_id }) => {
      this.createPeerConnection(connection_id, peer_id, portal_id);
    });

    this.handleEvent('create_offer', ({ connection_id, data_channels }) => {
      this.createOffer(connection_id, data_channels);
    });

    this.handleEvent('process_answer', ({ connection_id, answer }) => {
      this.processAnswer(connection_id, answer);
    });

    this.handleEvent('add_ice_candidate', ({ connection_id, candidate }) => {
      this.addIceCandidate(connection_id, candidate);
    });

    this.handleEvent('create_data_channel', ({ connection_id, channel_name, options }) => {
      this.createDataChannel(connection_id, channel_name, options);
    });

    this.handleEvent('close_connection', ({ connection_id }) => {
      this.closeConnection(connection_id);
    });

    console.log('Portal WebRTC Hook mounted');
  },

  createPeerConnection(connectionId, peerId, portalId) {
    try {
      const configuration = {
        iceServers: this.iceServers,
        iceCandidatePoolSize: 10
      };

      const peerConnection = new RTCPeerConnection(configuration);
      
      // Store connection
      this.connections.set(connectionId, {
        pc: peerConnection,
        peerId: peerId,
        portalId: portalId,
        state: 'new',
        dataChannels: new Map(),
        createdAt: new Date()
      });

      // Set up event handlers
      this.setupConnectionHandlers(connectionId, peerConnection);

      this.pushEvent('peer_connection_created', {
        connection_id: connectionId,
        peer_id: peerId,
        portal_id: portalId
      });

      console.log(`Created peer connection: ${connectionId} for peer: ${peerId}`);
    } catch (error) {
      console.error('Error creating peer connection:', error);
      this.pushEvent('peer_connection_error', {
        connection_id: connectionId,
        error: error.message
      });
    }
  },

  setupConnectionHandlers(connectionId, peerConnection) {
    // Connection state change
    peerConnection.onconnectionstatechange = () => {
      const state = peerConnection.connectionState;
      const connection = this.connections.get(connectionId);
      
      if (connection) {
        connection.state = state;
        connection.lastActivity = new Date();
      }

      this.pushEvent('connection_state_changed', {
        connection_id: connectionId,
        state: state
      });

      console.log(`Connection ${connectionId} state changed to: ${state}`);
    };

    // ICE connection state change
    peerConnection.oniceconnectionstatechange = () => {
      const iceState = peerConnection.iceConnectionState;
      
      this.pushEvent('ice_connection_state_changed', {
        connection_id: connectionId,
        ice_state: iceState
      });

      console.log(`ICE connection ${connectionId} state: ${iceState}`);
    };

    // ICE candidate gathering
    peerConnection.onicecandidate = (event) => {
      if (event.candidate) {
        this.pushEvent('ice_candidate_gathered', {
          connection_id: connectionId,
          candidate: {
            candidate: event.candidate.candidate,
            sdp_mid: event.candidate.sdpMid,
            sdp_mline_index: event.candidate.sdpMLineIndex
          }
        });
      }
    };

    // Data channel received
    peerConnection.ondatachannel = (event) => {
      const channel = event.channel;
      const channelName = channel.label;
      
      this.setupDataChannelHandlers(connectionId, channelName, channel);
      
      this.pushEvent('data_channel_received', {
        connection_id: connectionId,
        channel_name: channelName
      });

      console.log(`Received data channel: ${channelName} on connection: ${connectionId}`);
    };

    // Connection statistics
    setInterval(() => {
      this.reportConnectionStats(connectionId, peerConnection);
    }, 5000);
  },

  setupDataChannelHandlers(connectionId, channelName, channel) {
    const connection = this.connections.get(connectionId);
    if (connection) {
      connection.dataChannels.set(channelName, channel);
    }

    channel.onopen = () => {
      this.pushEvent('data_channel_opened', {
        connection_id: connectionId,
        channel_name: channelName
      });
      console.log(`Data channel opened: ${channelName}`);
    };

    channel.onclose = () => {
      this.pushEvent('data_channel_closed', {
        connection_id: connectionId,
        channel_name: channelName
      });
      console.log(`Data channel closed: ${channelName}`);
    };

    channel.onerror = (error) => {
      this.pushEvent('data_channel_error', {
        connection_id: connectionId,
        channel_name: channelName,
        error: error.message
      });
      console.error(`Data channel error: ${channelName}`, error);
    };

    channel.onmessage = (event) => {
      this.handleDataChannelMessage(connectionId, channelName, event.data);
    };
  },

  handleDataChannelMessage(connectionId, channelName, data) {
    // Handle different types of messages
    if (data instanceof ArrayBuffer) {
      // Binary data (file chunks)
      this.pushEvent('file_chunk_received', {
        connection_id: connectionId,
        channel_name: channelName,
        data: Array.from(new Uint8Array(data))
      });
    } else if (typeof data === 'string') {
      try {
        const message = JSON.parse(data);
        this.pushEvent('portal_message_received', {
          connection_id: connectionId,
          channel_name: channelName,
          message: message
        });
      } catch (e) {
        // Plain text message
        this.pushEvent('text_message_received', {
          connection_id: connectionId,
          channel_name: channelName,
          text: data
        });
      }
    }
  },

  async createOffer(connectionId, dataChannels = ['default']) {
    try {
      const connection = this.connections.get(connectionId);
      if (!connection) {
        throw new Error('Connection not found');
      }

      const peerConnection = connection.pc;

      // Create data channels
      for (const channelName of dataChannels) {
        const dataChannel = peerConnection.createDataChannel(channelName, {
          ordered: true,
          reliable: true
        });
        
        this.setupDataChannelHandlers(connectionId, channelName, dataChannel);
      }

      // Create offer
      const offer = await peerConnection.createOffer({
        offerToReceiveAudio: false,
        offerToReceiveVideo: false
      });

      await peerConnection.setLocalDescription(offer);

      this.pushEvent('offer_created', {
        connection_id: connectionId,
        offer: {
          type: offer.type,
          sdp: offer.sdp
        }
      });

      console.log(`Created offer for connection: ${connectionId}`);
    } catch (error) {
      console.error('Error creating offer:', error);
      this.pushEvent('offer_error', {
        connection_id: connectionId,
        error: error.message
      });
    }
  },

  async processAnswer(connectionId, answer) {
    try {
      const connection = this.connections.get(connectionId);
      if (!connection) {
        throw new Error('Connection not found');
      }

      const peerConnection = connection.pc;
      await peerConnection.setRemoteDescription(new RTCSessionDescription(answer));

      this.pushEvent('answer_processed', {
        connection_id: connectionId
      });

      console.log(`Processed answer for connection: ${connectionId}`);
    } catch (error) {
      console.error('Error processing answer:', error);
      this.pushEvent('answer_error', {
        connection_id: connectionId,
        error: error.message
      });
    }
  },

  async addIceCandidate(connectionId, candidate) {
    try {
      const connection = this.connections.get(connectionId);
      if (!connection) {
        throw new Error('Connection not found');
      }

      const peerConnection = connection.pc;
      await peerConnection.addIceCandidate(new RTCIceCandidate(candidate));

      this.pushEvent('ice_candidate_added', {
        connection_id: connectionId
      });

      console.log(`Added ICE candidate for connection: ${connectionId}`);
    } catch (error) {
      console.error('Error adding ICE candidate:', error);
      this.pushEvent('ice_candidate_error', {
        connection_id: connectionId,
        error: error.message
      });
    }
  },

  createDataChannel(connectionId, channelName, options = {}) {
    try {
      const connection = this.connections.get(connectionId);
      if (!connection) {
        throw new Error('Connection not found');
      }

      const peerConnection = connection.pc;
      const dataChannel = peerConnection.createDataChannel(channelName, {
        ordered: options.ordered !== false,
        reliable: options.reliable !== false
      });

      this.setupDataChannelHandlers(connectionId, channelName, dataChannel);

      this.pushEvent('data_channel_created', {
        connection_id: connectionId,
        channel_name: channelName
      });

      console.log(`Created data channel: ${channelName} for connection: ${connectionId}`);
    } catch (error) {
      console.error('Error creating data channel:', error);
      this.pushEvent('data_channel_error', {
        connection_id: connectionId,
        channel_name: channelName,
        error: error.message
      });
    }
  },

  sendData(connectionId, channelName, data) {
    try {
      const connection = this.connections.get(connectionId);
      if (!connection) {
        throw new Error('Connection not found');
      }

      const dataChannel = connection.dataChannels.get(channelName);
      if (!dataChannel) {
        throw new Error('Data channel not found');
      }

      if (dataChannel.readyState === 'open') {
        if (typeof data === 'string') {
          dataChannel.send(data);
        } else if (data instanceof ArrayBuffer) {
          dataChannel.send(data);
        } else {
          dataChannel.send(JSON.stringify(data));
        }

        console.log(`Sent data on channel: ${channelName}`);
      } else {
        console.warn(`Data channel ${channelName} is not open`);
      }
    } catch (error) {
      console.error('Error sending data:', error);
    }
  },

  closeConnection(connectionId) {
    try {
      const connection = this.connections.get(connectionId);
      if (connection) {
        // Close all data channels
        connection.dataChannels.forEach((channel) => {
          channel.close();
        });

        // Close peer connection
        connection.pc.close();

        // Remove from connections map
        this.connections.delete(connectionId);

        this.pushEvent('connection_closed', {
          connection_id: connectionId
        });

        console.log(`Closed connection: ${connectionId}`);
      }
    } catch (error) {
      console.error('Error closing connection:', error);
    }
  },

  async reportConnectionStats(connectionId, peerConnection) {
    try {
      const stats = await peerConnection.getStats();
      const connection = this.connections.get(connectionId);
      
      if (connection) {
        const statsData = {
          connection_id: connectionId,
          state: connection.state,
          data_channels: connection.dataChannels.size,
          uptime_seconds: Math.floor((new Date() - connection.createdAt) / 1000),
          last_activity: connection.lastActivity
        };

        // Extract RTC stats
        stats.forEach((report) => {
          if (report.type === 'outbound-rtp') {
            statsData.bytes_sent = report.bytesSent || 0;
            statsData.packets_sent = report.packetsSent || 0;
          } else if (report.type === 'inbound-rtp') {
            statsData.bytes_received = report.bytesReceived || 0;
            statsData.packets_received = report.packetsReceived || 0;
            statsData.packets_lost = report.packetsLost || 0;
          } else if (report.type === 'candidate-pair' && report.state === 'succeeded') {
            statsData.rtt = report.currentRoundTripTime || 0;
          }
        });

        this.pushEvent('connection_stats', statsData);
      }
    } catch (error) {
      console.error('Error getting connection stats:', error);
    }
  },

  destroyed() {
    // Clean up all connections
    this.connections.forEach((connection, connectionId) => {
      this.closeConnection(connectionId);
    });

    console.log('Portal WebRTC Hook destroyed');
  }
};
