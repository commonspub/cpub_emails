defmodule CommonsPub.Emails.Email do

  use Pointers.Mixin,
    otp_app: :cpub_emails,
    source: "cpub_emails_email"

  alias Pointers.Changesets
  require Pointers.Changesets
  alias CommonsPub.Emails.Email
  alias Ecto.Changeset
  
  mixin_schema do
    field :email, :string
    field :email_confirm_token, :string
    field :email_confirmed_at, :utc_datetime_usec
  end

  @defaults [
    cast:     [:email],
    required: [:email],
    email: [ format: ~r(^[^@]{1,128}@[^@\.]+\.[^@]{2,128}$) ],
  ]

  def changeset(email \\ %Email{}, attrs, opts \\ []) do
    Changesets.auto(email, attrs, opts, @defaults)
    |> put_token()
    |> Changeset.unique_constraint(:email)
  end

  def put_token(changeset)
  def put_token(%Changeset{valid?: true, changes: %{email: email}}=changeset) do
    token = Base.encode64(:crypto.strong_rand_bytes(16), padding: false)
    Changeset.put_change(changeset, :email_confirm_token, token)
  end
  def put_token(%Changeset{}=changeset), do: changeset

  def confirm(%Email{}=email) do
    email
    |> Changeset.cast(%{},[])
    |> Changeset.change(email_confirm_token: nil, email_confirmed_at: DateTime.utc_now())
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
      add :email_confirm_token, :text
      add :email_confirmed_at, :timestamptz
    end
    create_if_not_exists(unique_index(@email_table, [:email], index_opts))
    create_if_not_exists(unique_index(@email_table, [:email_confirm_token], index_opts))
  end

  def migrate_email(index_opts, :down) do
    drop_if_exists(unique_index(@email_table, [:email_confirm_token], index_opts))
    drop_if_exists(unique_index(@email_table, [:email], index_opts))
    drop_mixin_table(Email)
  end

end
