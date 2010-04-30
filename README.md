## TrustedParams

Trust only the params you indeed created inputs for (**experimental/half-assed/untested** solution
to the not solved [mass assignment problem](http://groups.google.com/group/rubyonrails-core/browse_thread/thread/3b6818496d0d07f1)).

### What It Does

Whenever you generate form with `form_tag` or `form_for` helper it registers
all the inputs added to the form, encrypts this information and appends
it to the form itself.

So it's just like `allow_forgery_protection` with it's `authenticity_token`
but for the given set of inputs.

Then when the form is submitted the set of trusted inputs/params
is extracted and available like this:

    params[:post].trusted

Any input/param that wasn't in original form will be removed.

### Installation

    rails plugin install git://github.com/dolzenko/trusted_params.git

### Pros

Really DRY, one-stop solution. Setup and forget about adding
to `attr_accessible` in your models. After all if you added
that input to the form - that *should* be accessible.

### Cons

Any param that's not added at the time of the request won't
get through by default.

All AJAX/API calls would need to submit ugly `trusted_params_token`
along with meaningful params.

To workaround this `trusted` can be passed the list of
params trusted by default:

    params[:post].trusted(:title, :body)

In such cases trusted params would be merged with `:title`,
and `:body` params when present.