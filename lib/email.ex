defmodule CommonsPub.Emails.Email do

  use Pointers.Mixin,
    otp_app: :cpub_emails,
    source: "cpub_emails_email"

  require Pointers.Changesets
  alias Pointers.Changesets
  alias CommonsPub.Emails.Email
  alias Ecto.Changeset
  
  mixin_schema do
    field :email, :string
    field :confirm_token, :string
    field :confirm_until, :utc_datetime_usec
    field :confirmed_at, :utc_datetime_usec
  end

  @default_confirm_duration {60 * 60 * 24, :second} # one day

  @defaults [
    cast:     [:email],
    required: [:email],
    email: [ format: ~r(^[^@]{1,128}@[^@\.]+\.[^@]{2,128}$) ],
  ]

  def changeset(email \\ %Email{}, attrs, opts \\ []) do
    Changesets.auto(email, attrs, opts, @defaults)
    |> put_token_on_email_change()
    |> Changeset.unique_constraint(:email)
  end

  @doc false
  def put_token_on_email_change(changeset)
  def put_token_on_email_change(%Changeset{valid?: true, changes: %{email: email}}=changeset) do
    if Changesets.config_for(__MODULE__, :must_confirm, true),
      do: put_token(changeset),
      else: Changeset.change(changeset, confirmed_at: DateTime.utc_now())
  end
  def put_token_on_email_change(%Changeset{}=changeset), do: changeset

  @doc """
  Changeset function. Unconditionally sets the user as unconfirmed,
  generates a confirmation token and puts an expiry on it determined
  by the `:confirm_duration` config key (default one day).
  """
  def put_token(%Email{}=email), do: put_token(Changeset.cast(email, %{}, []))
  def put_token(%Changeset{}=changeset) do
    {count, unit} = Changesets.config_for(__MODULE__, :confirm_duration, @default_confirm_duration)
    token = Base.encode32(:crypto.strong_rand_bytes(16), padding: false)
    until = DateTime.add(DateTime.utc_now(), count, unit)
    Changeset.change(changeset, confirmed_at: nil, confirm_token: token, confirm_until: until)
  end    

  @doc """
  Changeset function. Marks the user's email as confirmed and removes
  their confirmation token.
  """
  def confirm(%Email{}=email) do
    email
    |> Changeset.cast(%{}, [])
    |> Changeset.change(confirm_token: nil, confirm_until: nil, confirmed_at: DateTime.utc_now())
  end

end
defmodule CommonsPub.Emails.Email.Migration do

  import Ecto.Migration
  import Pointers.Migration
  alias CommonsPub.Emails.Email

  @email_table Email.__schema__(:source)

  def migrate_email(index_opts \\ [], dir \\ direction())

  def migrate_email(index_opts, :up) do
    create_mixin_table(Email) do
      add :email, :text, null: false
      add :confirm_token, :text
      add :confirm_until, :timestamptz
      add :confirmed_at, :timestamptz
    end
    create_if_not_exists(unique_index(@email_table, [:email], index_opts))
    create_if_not_exists(unique_index(@email_table, [:confirm_token], index_opts))
  end

  def migrate_email(index_opts, :down) do
    drop_if_exists(unique_index(@email_table, [:confirm_token], index_opts))
    drop_if_exists(unique_index(@email_table, [:email], index_opts))
    drop_mixin_table(Email)
  end

end
