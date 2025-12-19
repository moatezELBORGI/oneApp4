/*
  # Add video call support

  1. Changes
    - Add `is_video_call` column to calls table (default false for audio calls)
    - Calls start as audio-only, can be upgraded to video during the call

  2. Notes
    - By default, all calls start as audio-only (is_video_call = false)
    - Users can request to upgrade to video during an active call
*/

-- Add is_video_call column with default false
ALTER TABLE calls
ADD COLUMN IF NOT EXISTS is_video_call BOOLEAN NOT NULL DEFAULT false;

-- Create index for better performance when filtering by video/audio calls
CREATE INDEX IF NOT EXISTS idx_calls_is_video ON calls(is_video_call);
