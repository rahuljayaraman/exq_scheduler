defmodule ExqScheduler.Schedule.Parser do
  alias ExqScheduler.Schedule.Utils
  @cron_key "cron"
  @every_key "every"
  @description_key "description"
  @non_job_keys [@cron_key, @every_key, @description_key]

  @doc """
    Parses the schedule as per the format (rufus-scheduler supported):
    %{
      cron => "* * * * *" or ["* * * * *", {first_in: "5m"}]
      every => "15m",
      class => "SidekiqWorker",
      queue => "high",
      args => "/tmp/poop"
    }
  """
  def get_schedule(schedule) do
    has_cron = Map.has_key?(schedule, @cron_key)
    has_every = Map.has_key?(schedule, @every_key)

    if !has_cron and !has_every do
      nil
    else
      schedule_time_key =
        if has_cron do
          @cron_key
        else
          @every_key
        end

      schedule_time = Map.fetch!(schedule, schedule_time_key)
      description = Map.get(schedule, @description_key, "")

      unless is_bitstring(schedule_time) or List.ascii_printable?(schedule_time) do
        [schedule_time, schedule_opts] = schedule_time

        {
          description,
          normalize_time(schedule_time_key, schedule_time),
          create_job(schedule),
          schedule_opts
        }
      else
        {
          description,
          normalize_time(schedule_time_key, schedule_time),
          create_job(schedule),
          %{}
        }
      end
    end
  end

  defp normalize_time(key, time) do
    time = to_string(time)

    if key == @every_key do
      Utils.every_to_cron(time)
    else
      Utils.to_cron_exp(time)
      |> elem(0)
      |> Crontab.CronExpression.Composer.compose()
    end
  end

  defp create_job(schedule) do
    Map.drop(schedule, @non_job_keys) |> Poison.encode!()
  end
end
