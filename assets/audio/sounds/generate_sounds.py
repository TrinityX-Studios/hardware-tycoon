import math
import struct
import os

def create_wave_file(filename, sample_rate, num_channels, bits_per_sample, data):
    byte_rate = sample_rate * num_channels * (bits_per_sample // 8)
    block_align = num_channels * (bits_per_sample // 8)
    subchunk2_size = len(data)
    chunk_size = 36 + subchunk2_size

    header = struct.pack(
        '<4sI4s4sIHHIIHH4sI',
        b'RIFF', chunk_size, b'WAVE',
        b'fmt ', 16, 1, num_channels, sample_rate, byte_rate, block_align, bits_per_sample,
        b'data', subchunk2_size
    )

    with open(filename, 'wb') as f:
        f.write(header)
        f.write(data)

def generate_click():
    # Crisp, high-pitched mechanical click (30ms duration)
    sample_rate = 22050
    duration = 0.03
    num_samples = int(sample_rate * duration)
    data = bytearray()
    
    for i in range(num_samples):
        t = i / sample_rate
        # Frequency starts at 2000Hz and drops, envelope decays rapidly
        freq = 2000.0 * (1.0 - t / duration)
        envelope = math.exp(-150.0 * t)
        val = math.sin(2 * math.pi * freq * t) * envelope
        
        # 16-bit PCM conversion
        sample = int(val * 32767)
        data.extend(struct.pack('<h', max(-32768, min(32767, sample))))
        
    return sample_rate, data

def generate_error():
    # Classic retro dual-tone warning buzzer (200ms duration)
    sample_rate = 22050
    duration = 0.20
    num_samples = int(sample_rate * duration)
    data = bytearray()
    
    for i in range(num_samples):
        t = i / sample_rate
        # Dual low-frequency square-ish wave
        envelope = 1.0 if t < 0.15 else (1.0 - (t - 0.15) / 0.05)
        # Combine 150Hz and 175Hz sine waves
        val1 = math.sin(2 * math.pi * 150.0 * t)
        val2 = math.sin(2 * math.pi * 175.0 * t)
        val = 0.5 * (val1 + val2) * envelope
        # Add slight clipping for retro crunch
        if val > 0.5: val = 0.5
        elif val < -0.5: val = -0.5
        
        # Scale back to full volume
        val = val * 2.0 * 0.7
        
        sample = int(val * 32767)
        data.extend(struct.pack('<h', max(-32768, min(32767, sample))))
        
    return sample_rate, data

def generate_success():
    # Uplifting arpeggiated retro chime (350ms duration)
    sample_rate = 22050
    duration = 0.35
    num_samples = int(sample_rate * duration)
    data = bytearray()
    
    # 4 notes of the arpeggio (C5, E5, G5, C6)
    freqs = [523.25, 659.25, 783.99, 1046.50]
    note_duration = duration / len(freqs)
    
    for i in range(num_samples):
        t = i / sample_rate
        # Determine active note based on elapsed time
        note_idx = int(t / note_duration)
        if note_idx >= len(freqs):
            note_idx = len(freqs) - 1
            
        freq = freqs[note_idx]
        
        # Dynamic volume envelope per note
        t_note = t % note_duration
        note_env = math.exp(-8.0 * t_note)
        
        # Overall fade out at the very end of the chime
        overall_env = 1.0 if t < 0.25 else (1.0 - (t - 0.25) / 0.10)
        
        val = math.sin(2 * math.pi * freq * t) * note_env * overall_env
        
        sample = int(val * 32767)
        data.extend(struct.pack('<h', max(-32768, min(32767, sample))))
        
    return sample_rate, data

if __name__ == '__main__':
    target_dir = 'assets/audio/sounds'
    os.makedirs(target_dir, exist_ok=True)
    
    # Click
    sr, d = generate_click()
    create_wave_file(os.path.join(target_dir, 'click.wav'), sr, 1, 16, d)
    
    # Error
    sr, d = generate_error()
    create_wave_file(os.path.join(target_dir, 'error.wav'), sr, 1, 16, d)
    
    # Success
    sr, d = generate_success()
    create_wave_file(os.path.join(target_dir, 'success.wav'), sr, 1, 16, d)
    
    print("Retro WAV sound effects successfully generated.")
