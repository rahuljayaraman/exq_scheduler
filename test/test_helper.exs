ExUnit.start()

defmodule TestUtils do
  alias ExqScheduler.Schedule
  alias ExqScheduler.Schedule.TimeRange
  alias ExqScheduler.Storage
  alias ExqScheduler.Storage.Redis

  def build_schedule(cron) do
    {:ok, job} = %{class: "TestJob"} |> Poison.encode()
    Schedule.new("test_schedule", "test description", cron, job, %{})
  end

  def build_time_range(now, offset) do
    t_start = now |> Timex.shift(seconds: -offset)
    t_end = now |> Timex.shift(seconds: offset)
    %TimeRange{t_start: t_start, t_end: t_end}
  end

  def build_scheduled_jobs(cron, offset, now \\ Timex.now()) do
    schedule = build_schedule(cron)
    time_range = build_time_range(now, offset)
    Schedule.get_jobs(schedule, time_range)
  end

  def storage_opts do
    ExqScheduler.build_storage_opts(false)
  end

  def flush_redis do
    Redis.flushdb(storage_opts().redis)
  end

  def default_queue_job_count do
    opts = storage_opts()
    queue_name = Storage.queue_key("default", opts)
    Redis.queue_len(opts.redis, queue_name)
  end

  def pmap(collection, func) do
    collection
    |> Enum.map(&Task.async(fn -> func.(&1) end))
    |> Enum.map(&Task.await/1)
  end
end
